//
//  AddressBookService.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Contacts
import Foundation

class AddressBookService {
    typealias AuthorizationCompletionBlock = (_ granted: Bool, _ error: Error?) -> Void

    private lazy var store: CNContactStore = .init()

    func hasAccessToAddressBook() -> Bool {
        return CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }

    func requestAuthorizationWithCompletion(_ completion: @escaping AuthorizationCompletionBlock) {
        store.requestAccess(for: .contacts, completionHandler: completion)
    }

    func getAllDeviceContacts(completion: @escaping ([CNContact]) -> Void) {
        DispatchQueue.global().async {
            completion(self.getAllContacts())
        }
    }

    private func getAllContacts() -> [CNContact] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
            /*
                 this key needs special entitlement since iOS 13 SDK, which should be approved by Apple stuff
                 more info: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_contacts_notes
                 commented out until beaurocracy resolved
                */
            // CNContactNoteKey as CNKeyDescriptor,
            CNContactVCardSerialization.descriptorForRequiredKeys()
        ]

        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try store.containers(matching: nil)
        } catch {}

        var results: [CNContact] = []

        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            do {
                let containerResults = try store.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch)
                results.append(contentsOf: containerResults)
            } catch {}
        }

        return results
    }

    func fetchDeviceContactsInContactVO(completion: @escaping ([ContactVO]) -> Void) {
        getAllDeviceContacts { deviceContacts in
            guard !deviceContacts.isEmpty else {
                completion([])
                return
            }
            var results: [ContactVO] = []
            for contact in deviceContacts {
                var name: String = [
                    contact.givenName,
                    contact.middleName,
                    contact.familyName
                ].filter { !$0.isEmpty }.joined(separator: " ")
                let emails = contact.emailAddresses
                for email in emails {
                    let emailAsString = email.value as String
                    if emailAsString.isValidEmail() {
                        let email = emailAsString
                        if name.isEmpty {
                            name = email
                        }
                        results.append(ContactVO(name: name, email: email, isProtonMailContact: false))
                    }
                }
            }
            completion(results)
        }
    }
}
