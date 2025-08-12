// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest
import ProtonCoreCrypto
@testable import ProtonMail

final class PushNotificationHandlerTests: XCTestCase {
    typealias InMemorySaver = PushNotificationServiceTests.InMemorySaver

    var sut: PushNotificationHandler!
    private var mockPushDecryptionKeysProvider: MockPushDecryptionKeysProvider!
    private var mockKitSaver: InMemorySaver<Set<PushSubscriptionSettings>>!
    private var mockFailedPushMarker: MockFailedPushDecryptionMarker!

    private let dummyUID = UUID().uuidString
    private let dummyKeyPair = DummyKeyPair()

    override func setUp() {
        super.setUp()
        mockPushDecryptionKeysProvider = .init()
        mockPushDecryptionKeysProvider.pushNotificationsDecryptionKeysStub.fixture = [
            DecryptionKey(
                privateKey: ArmoredKey(value: dummyKeyPair.privateKey),
                passphrase: Passphrase(value: dummyKeyPair.passphrase)
            )
        ]
        mockKitSaver = .init()
        mockFailedPushMarker = .init()
        let dependencies = PushNotificationHandler.Dependencies(
            decryptionKeysProvider: mockPushDecryptionKeysProvider,
            oldEncryptionKitSaver: mockKitSaver,
            failedPushDecryptionMarker: mockFailedPushMarker
        )
        sut = PushNotificationHandler(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        mockPushDecryptionKeysProvider = nil
        sut = nil
    }

    func testHandle_whenIsEmailNotification_shouldProperlyDecryptNotification() {
        let testBody = "Test subject"
        let testSender = "A sender"
        let identifier = UUID().uuidString
        let request = mailNotificationRequest(identifier: identifier, sender: testSender, body: testBody)

        let expectation = self.expectation(description: "Decryption expectation")
        sut.handle(request: request) { decryptedContent in
            XCTAssertEqual(decryptedContent.threadIdentifier, self.dummyUID)
            XCTAssertEqual(decryptedContent.title, testSender)
            XCTAssertEqual(decryptedContent.body, testBody)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testHandle_whenIsOpenUrlNotification_shouldProperlyDecryptNotification() {
        let expectedSender = "ProntonMail"
        let expectedBody = "New sign in to your account"
        let identifier = UUID().uuidString
        let request = mailNotificationRequest(identifier: identifier, sender: expectedSender, body: expectedBody)

        let expectation = self.expectation(description: "Decryption expectation")
        sut.handle(request: request) { decryptedContent in
            XCTAssertEqual(decryptedContent.threadIdentifier, self.dummyUID)
            XCTAssertEqual(decryptedContent.title, expectedSender)
            XCTAssertEqual(decryptedContent.body, expectedBody)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testHandle_whenNotificationDecryptionFails_shouldMarkDecryptionFailed() {
        let request = mailNotificationRequest(identifier: UUID().uuidString, sender: "", body: "")
        mockPushDecryptionKeysProvider.pushNotificationsDecryptionKeysStub.fixture = []

        let expectation = self.expectation(description: "Decryption expectation")
        sut.handle(request: request) { decryptedContent in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockFailedPushMarker.markPushNotificationDecryptionFailureStub.callCounter, 1)
    }

    /// This test checks that stored encryption kits before the push encryption refactor are also used to decrypt pushes
    func testHandle_whenKeyInOldEncryptionKitSaverImplementation_shouldProperlyDecryptNotification() {
        let testBody = "Test subject"
        let testSender = "A sender"
        let identifier = UUID().uuidString
        let request = mailNotificationRequest(identifier: identifier, sender: testSender, body: testBody)

        var pushSubscriptionSetting = PushSubscriptionSettings(token: "", UID: dummyUID)
        pushSubscriptionSetting.encryptionKit = .init(
            passphrase: dummyKeyPair.passphrase,
            privateKey: dummyKeyPair.privateKey,
            publicKey: dummyKeyPair.publicKey.value
        )
        mockKitSaver.set(newValue: Set([pushSubscriptionSetting]))
        mockPushDecryptionKeysProvider.pushNotificationsDecryptionKeysStub.fixture = []

        let expectation = self.expectation(description: "Decryption expectation")
        sut.handle(request: request) { decryptedContent in
            XCTAssertEqual(decryptedContent.threadIdentifier, self.dummyUID)
            XCTAssertEqual(decryptedContent.title, testSender)
            XCTAssertEqual(decryptedContent.body, testBody)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

private extension PushNotificationHandlerTests {
    private func mailNotificationRequest(identifier: String, sender: String, body: String) -> UNNotificationRequest {
        let plainTextPayload = """
        {
          "data": {
            "title": "ProtonMail",
            "subtitle": "",
            "body": "\(body)",
            "sender": {
              "Name": "\(sender)",
              "Address": "foo@bar.com",
              "Group": ""
            },
            "vibrate": 1,
            "sound": 1,
            "largeIcon": "large_icon",
            "smallIcon": "small_icon",
            "badge": \(Int.random(in: 0..<100)),
            "messageId": "\(UUID().uuidString)"
          },
          "type": "email",
          "version": 2
        }
        """
        let encryptedPayload = try! Encryptor.encrypt(
            publicKey: dummyKeyPair.publicKey,
            cleartext: plainTextPayload
        ).value
        let userInfo: [NSString: Any?] = [
            "UID": dummyUID,
            "unreadConversations": nil,
            "unreadMessages": Int.random(in: 0..<100),
            "viewMode": Int.random(in: 0...1),
            "encryptedMessage": encryptedPayload,
            "aps": ["alert": "New message received",
                    "badge": Int.random(in: 0..<100),
                    "mutable-content": 1]
        ]
        let content = UNMutableNotificationContent()
        content.userInfo = userInfo as [AnyHashable: Any]
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: nil)
        return request
    }

    private func openUrlNotificationRequest(identifier: String, sender: String, body: String) -> UNNotificationRequest {
        let encryptedPayload = PushEncryptedMessageTestData
            .openUrlNotification(with: dummyKeyPair, sender: sender, body: body)
        let userInfo: [NSString: Any?] = [
            "UID": dummyUID,
            "unreadConversations": nil,
            "unreadMessages": Int.random(in: 0..<100),
            "viewMode": Int.random(in: 0...1),
            "encryptedMessage": encryptedPayload,
            "aps": ["alert": "New message received",
                    "badge": Int.random(in: 0..<100),
                    "mutable-content": 1]
        ]
        let content = UNMutableNotificationContent()
        content.userInfo = userInfo as [AnyHashable: Any]
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: nil)
        return request
    }
}
