# Proton Mail

## Trust Model
x  | Device Storage | Device Memory | Keychain | SecureEnclave | Transport | iCloud | Inbox | Outbox
--- | --- | --- | --- | --- | --- | --- | --- | ---
Trust level | **Low** | **Moderate** | **Low** | **High** | **Low** | **Low** | **Low** | **Moderate**
Compromise conditions | Sandbox escape is enough | Requires either kernel compromised or binary modified, coupled to app version | Codesigning compromise is enough | No known attacks yet | Person in the middle attacks | Not controlled by us | Possible malicious content | Can include quote from incoming message
Solution | MainKey | Not much can be done | MainKey | _ | Certificate pinning | Do not use | DOMPurify, CSP, no JS in WebViews | DOMPurify, CSP

## Local Data
As most iOS appications, our application needs to store some data locally:
- encrypted messages and attachments cache
- private and public keys for sending and reading messages
- access token for communication with back end
- token for push notification payload decryption
- details of user account

Some of these pieces of data is kept in Keychain, some in our local CoreData database, and some in UserDefaults dictionary inside the application directory. iOS offers high level of data protection using Keychain Data Protection and File Data Protection classes, but on top of them we've introduced our own additional layer of protection called MainKey mechanism (for cases when user has TouchID/FaceID or PIN is active).

Object | Access | Disclosure | Modification | Access denial
--- | --- | --- | --- | ---
Auth token | **High**: allows to steal session | **High**: session can be closed from website | **Low**: wrong token leads to correct logout | **Low**: no token leads to correct logout
Mailbox Password (this is not Login Password!) | **Critical**: allows decryption of messages, contacts and attachments | **Critical**: in 2 password mode can be reused by user on other services | **Low**: wrong value will not decrypt local data and will throw user to Mailbox Password screen | **Low**: wrong value will not decrypt mailbox and will throw user to Mailbox Password screen
Email Private and Public Keys | **Critical**: allows decryption of messages caught in the air | **Critical**: allows decryption of old messages | **Moderate**: messages will not be properly decrypted | **Moderate**: messages will not be properly decrypted
CoreData (Messages, Attachments, Contacts, Labels) | **Critical** |  **Critical** | **Critical**: can mislead user on this device until relogin | **Moderate**: poor UX
Username | **Critical**: connects account to person | **Critical**: connects account to person | **Low** | **Low**
Settings | **Low** | **Low** | **High**: can affect privacy if not noticed by user (Autoload Images, Remove image meta-data) | **Low**
Push payload encryption key | **High**: push payload contains senders name and message title  | **Low**: key is per-session, iOS does not keep pushes on device for long | **Low** | **Low**

### Default Data Protection
Most Keychain items are saved with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` flag. We could not use more strict flags because its pretty common that app needs to complete its work in background even when the device is locked - for example, when user is sending email with heavy attachments. In order to share them across all our application extensions (Share and Push Application Extensions), we keep them in one Keychain Access Group. We do not want them to be restorable from backup on ther devices.

Data protection class for files is set as `NSFileProtectionComplete` in app entitlements with a default exceptions for CoreData and UserDefaults files, which we need to access in background and when the device is locked.

More information is available in [iOS Security](https://www.apple.com/business/docs/site/iOS_Security_Guide.pdf) documentation.

### MainKey Encryption
In order to increase our chances to protect the data when iOS sandbox is compromised or when rouge applicatoin managed to dump keychain, we've introduced MainKey protection system.
The idea is to encrypt all sensible local data with per-login local key called MainKey, which will not be stored in compromisable places.

MainKey may be persisted by means of 2 techniques:
- _TouchID/FaceID protection._ SecureEnclave chip generates asymmetric keypair, keep private key inside and give public key to the app. We encrypt MainKey with public key and save to Keychain, asking SecureEnclave to decrypt it every time we need to retrieve cleartext MainKey. SecureEnclave decrypt the MainKey only after biometric authentication or device passcode and the private key never leaves it.
- _PIN protection._ We can derive temporary key from user-input PIN string, symmetrically encrypt MainKey with this temporary key and save cyphertext to Keychain. Temporary key and PIN string are never persisted and are removed from memory as fast as possible. No PIN input - no access to MainKey.
- _No protection._ For cases when user does not want to switch on additional protection in app Settings, MainKey is saved cleartext in Keychain. This case is weak against forensic attacks in cases when device is compromised, but the data should not be extractable from backups. This case is trivial and will not be discussed furter.

MainKey protects:
1. Most attributes of items saved in CoreData
2. User account and user's encryption keys
3. Access token

On every app launch MainKey cyphertext from Keychain should be decrypted and placed into memory of the app process before any other part of the app will start its work. That's why the app is not functional unless user enters PIN/TouchID/FaceID - the app can not access local data and does not know anything about user to request data from server.
Side effect of this architecture is that Share extension requires authentication every time, as it runs in separate process.

MainKey is kept in memory of the app process according to Autolock Time settings: it can be removed from memory after certain amount of time or each time apps goes background.

## Dependency injection

We're using [Factory](https://github.com/hmlongco/Factory) combined with protocol composition (to avoid making all dependencies accessible everywhere) and glued together with Sourcery.

### Declaring dependencies

Every class that can be considered a dependency (i.e. needs to be injected to an instance of another class) has an associated protocol named `Has` + the name of that class. For example, `HasUsersManager`.

The `Has` protocol requires a single property of the type specified in its name.

The classes that require dependencies declare them using typealiases and protocol composition:

```swift
class MyClass {
    typealias Dependencies = HasUsersManager & HasQueueManager & ...

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func doSomething() {
        if dependencies.usersManager.users.isEmpty {
            dependencies.queueManager.doSomething()
        }
    }
}
```

Then we have container classes that expose the dependencies by implementing the `Has` protocols:

```swift
class GlobalContainer {
    ...
}

extension GlobalContainer: HasUsersManager {
    var usersManager: UsersManager {
        ...
    }
}

extension GlobalContainer: HasQueueManager {
    var queueManager: HasQueueManager {
        ...
    }
}
```

Because some of our dependencies are tied to a specific `UserManager`, they cannot be tied to any shared container, so we use a user-specific `UserContainer` to store them.

When instantiating a class, we pass the whole container to its `init(dependencies:)`, but the class only "sees" the dependencies declared in its `typealias Dependencies` - so we do not obscure its dependencies like we would, for example, using a service locator.

### Injecting dependencies

As mentioned above, we're using Factory to resolve the dependencies.

Before we register a new dependency in a container, we have to determine _which_ container to add it to.

If the dependency is user-specific, add it to `UserContainer`, otherwise add it to `GlobalContainer`.

If the class you're adding is only know to the main app target, add it under `DI/APP`, otherwise add it under `DI/APP_share`.

Steps to add the dependency:

1. Add a computed variable of type `Factory<YourClass>` as you normally would with Factory.
    * Important: the name of this variable must be the property name you want with the word "Factory" appended. If you don't append it, Sourcery won't pick the variable up.
2. Run Sourcery (for example by building the project).
3. A new protocol named `Has$YourClass` will be created.
    * The property name is the name of the computed variable you picked in step 1 with the "Factory" suffix removed.
4. Add it to the `typealias Dependencies` of the class that needs it.
5. You can now access `dependencies.$propertyName` inside that class.

Example code:

```swift
extension GlobalContainer {
    var usersManagerFactory: Factory<UsersManager> {
        self {
            UsersManager(
                doh: BackendConfiguration.shared.doh,
                userDataCache: UserDataCache(keyMaker: self.keyMaker),
                coreKeyMaker: self.keyMaker
            )
        }
    }
}
```
