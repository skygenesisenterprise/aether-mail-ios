// Copyright (c) 2022 Proton AG
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

import CoreData
@testable import ProtonMail
import XCTest

final class MessageEntityTests: XCTestCase {
    private var contactPickerModelHelper: ContactPickerModelHelper!
    private var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        let testContainer = TestContainer()
        contactPickerModelHelper = .init(contextProvider: testContainer.contextProvider)
        testContext = testContainer.contextProvider.mainContext
    }

    override func tearDown() {
        super.tearDown()
        testContext = nil
    }

    func testInitialization() throws {
        let message = Message(context: testContext)
        let messageID = MessageID.generateLocalID().rawValue

        message.messageID = messageID
        message.action = NSNumber(value: 2)
        message.addressID = "addressID-0123"
        message.body = "body-0987"
        message.conversationID = "conversationID-0123"
        message.expirationTime = .distantPast
        message.header = "header-0987"
        message.numAttachments = NSNumber(value: 3)
        message.sender = """
        {"Address":"sender@proton.me","Name":"test00","IsProton": 1}
        """
        message.toList = """
        [{"Address":"to1@proton.me","Name":"testTO01"},{"Address":"to2@proton.me","Name":"testTO02"}]
        """
        message.ccList = """
        [{"Address":"cc1@proton.me","Name":"testCC01"},{"Address":"cc2@proton.me","Name":"testCC02"}]
        """
        message.bccList = """
        [{"Address":"bcc1@proton.me","Name":"testBCC01"},{"Address":"bcc2@proton.me","Name":"testBCC02"}]
        """
        message.size = 300
        message.spamScore = 101
        message.time = .distantFuture
        message.title = "title-0123"
        message.unRead = true
        message.userID = "userID-0987"
        message.order = NSNumber(value: 100)
        message.nextAddressID = "nextAddressID-0123"
        message.expirationOffset = 50
        message.isSoftDeleted = true
        message.isDetailDownloaded = true
        message.messageStatus = NSNumber(value: 1)
        message.lastModified = Date(timeIntervalSince1970: 1645686077)
        message.orginalMessageID = "originalID-0987"
        message.orginalTime = Date(timeIntervalSince1970: 645686077)
        message.passwordEncryptedBody = "encrypted-0123"
        message.password = "password-0987"
        message.passwordHint = "hint-0123"

        let entity = MessageEntity(message)
        XCTAssertEqual(entity.messageID, MessageID(messageID))
        XCTAssertEqual(entity.addressID, AddressID("addressID-0123"))
        XCTAssertEqual(entity.body, "body-0987")
        XCTAssertEqual(entity.conversationID, ConversationID("conversationID-0123"))
        XCTAssertEqual(entity.expirationTime, .distantPast)
        XCTAssertEqual(entity.numAttachments, 3)
        let sender = try entity.parseSender()
        XCTAssertEqual(sender.address, "sender@proton.me")
        XCTAssertEqual(sender.name, "test00")
        XCTAssertTrue(sender.isFromProton)
        XCTAssertEqual(entity.size, 300)
        XCTAssertEqual(entity.spamScore, .dmarcFail)
        XCTAssertEqual(entity.time, .distantFuture)
        XCTAssertEqual(entity.title, "title-0123")
        XCTAssertTrue(entity.unRead)
        XCTAssertEqual(entity.userID, UserID("userID-0987"))
        XCTAssertEqual(entity.order, 100)
        XCTAssertEqual(entity.nextAddressID, AddressID("nextAddressID-0123"))
        XCTAssertEqual(entity.expirationOffset, 50)
        XCTAssertTrue(entity.isSoftDeleted)
        XCTAssertTrue(entity.isDetailDownloaded)
        XCTAssertTrue(entity.hasMetaData)
        XCTAssertEqual(entity.lastModified, Date(timeIntervalSince1970: 1645686077))
        XCTAssertEqual(entity.originalMessageID, MessageID("originalID-0987"))
        XCTAssertEqual(entity.originalTime, Date(timeIntervalSince1970: 645686077))
        XCTAssertEqual(entity.passwordEncryptedBody, "encrypted-0123")
        XCTAssertEqual(entity.password, "password-0987")
        XCTAssertEqual(entity.passwordHint, "hint-0123")
        XCTAssertEqual(entity.rawTOList, message.toList)
        XCTAssertEqual(entity.rawCCList, message.ccList)
        XCTAssertEqual(entity.rawBCCList, message.bccList)
        XCTAssertEqual(entity.recipientsTo, ["to1@proton.me", "to2@proton.me"])
        XCTAssertEqual(entity.recipientsCc, ["cc1@proton.me", "cc2@proton.me"])
        XCTAssertEqual(entity.recipientsBcc, ["bcc1@proton.me", "bcc2@proton.me"])
    }

    func testContactsConvert() throws {
        let message = Message(context: testContext)
        message.messageID = MessageID.generateLocalID().rawValue
        message.ccList = """
        [
                {
                  "Name": "test01",
                  "Address": "test01@proton.me",
                  "Group": ""
                },
                {
                  "Name": "test02",
                  "Address": "test02@proton.me",
                  "Group": ""
                }
              ]
        """
        var entity = MessageEntity(message)
        XCTAssertEqual(entity.recipientsCc.count, 2)

        message.ccList = """
        [
                {
                  "Name": "test01",
                  "Address": "test01@proton.me",
                  "Group": "testGroup"
                },
                {
                  "Name": "test02",
                  "Address": "test02@proton.me",
                  "Group": "testGroup"
                }
              ]
        """
        entity = MessageEntity(message)
        XCTAssertEqual(entity.recipientsCc.count, 2)

        let ccList = contactPickerModelHelper.contacts(from: entity.rawCCList)
        XCTAssertEqual(ccList.count, 1)
        let contact = try XCTUnwrap(ccList.first as? ContactGroupVO)
        XCTAssertEqual(contact.contactTitle, "testGroup")
        let mails = contact.getSelectedEmailData()
        XCTAssertEqual(mails.count, 2)
        for data in mails {
            if data.name == "test01" {
                XCTAssertEqual(data.email, "test01@proton.me")
            } else {
                XCTAssertEqual(data.name, "test02")
                XCTAssertEqual(data.email, "test02@proton.me")
            }
        }
    }

    func testParseUnsubscribeMethods() throws {
        let message = Message(context: testContext)
        message.unsubscribeMethods = """
        {
            "OneClick": "one click method",
            "HttpClient": "http client method",
            "Mailto": {
                "ToList": ["a", "b", "c"],
                "Subject": "This is a subject",
                "Body": "This is a body"
            }
        }
        """
        var entity = MessageEntity(message)
        let method = try XCTUnwrap(entity.unsubscribeMethods)
        XCTAssertEqual(method.oneClick, "one click method")
        XCTAssertEqual(method.httpClient, "http client method")

        message.unsubscribeMethods = "jfelkdfl"
        entity = MessageEntity(message)
        XCTAssertNil(entity.unsubscribeMethods)

        message.unsubscribeMethods = nil
        entity = MessageEntity(message)
        XCTAssertNil(entity.unsubscribeMethods)
    }

    func testParsedHeader() throws {
        let message = Message(context: testContext)
        message.parsedHeaders = """
        {
            "Return-Path": "<793-XLJ>",
            "X-Original-To": "test01@proton.me",
            "Delivered-To": "test01@proton.me",
            "Authentication-Results": [
              "mailin010.protonmail.ch; dkim=pass",
              "mailin010.protonmail.ch; dmarc=none",
              "mailin010.protonmail.ch; spf=pass",
              "mailin010.protonmail.ch; arc=none",
              "mailin010.protonmail.ch; dkim=pass"
            ],
            "number": 3
        }
        """
        let entity = MessageEntity(message)
        let dict = entity.parsedHeaders
        XCTAssertEqual(dict.keys.count, 5)
        XCTAssertEqual(dict["Return-Path"] as? String, "<793-XLJ>")
        XCTAssertEqual(dict["X-Original-To"] as? String, "test01@proton.me")
        XCTAssertEqual(dict["Delivered-To"] as? String, "test01@proton.me")
        XCTAssertEqual(dict["number"] as? Int, 3)
        let authResults: [String] = try XCTUnwrap(dict["Authentication-Results"] as? [String])
        XCTAssertEqual(authResults.count, 5)
        XCTAssertEqual(authResults[2], "mailin010.protonmail.ch; spf=pass")
        XCTAssertEqual(authResults[4], "mailin010.protonmail.ch; dkim=pass")
    }

    func testAutoDeletingMessageShouldBeTrueIfSpamWithExpirationTimeAndWithNonFrozenExpiration() {
        let location = Message.Location.spam
        let expirationTime = Date()
        let isFrozenFalse = Int64.min
        let sut = MessageEntity.make(rawFlag: isFrozenFalse,
                                     expirationTime: expirationTime,
                                     labels: [LabelEntity.make(labelID: location.labelID)])
        XCTAssertTrue(sut.isAutoDeleting)
    }

    func testAutoDeletingMessageShouldBeTrueIfTrashWithExpirationTimeAndWithNonFrozenExpiration() {
        let location = Message.Location.spam
        let expirationTime = Date()
        let isFrozenFalse = Int64.min
        let sut = MessageEntity.make(rawFlag: isFrozenFalse,
                                     expirationTime: expirationTime,
                                     labels: [LabelEntity.make(labelID: location.labelID)])
        XCTAssertTrue(sut.isAutoDeleting)
    }

    func testAutoDeletingMessageShouldBeFalseIfLocationOtherThanSpamTrash() {
        let location = Message.Location.inbox
        let expirationTime = Date()
        let isFrozenFalse = Int64.min
        let sut = MessageEntity.make(rawFlag: isFrozenFalse,
                                     expirationTime: expirationTime,
                                     labels: [LabelEntity.make(labelID: location.labelID)])
        XCTAssertFalse(sut.isAutoDeleting)
    }

    func testAutoDeletingMessageShouldBeFalseIfExpirationTimeIsNil() {
        let location = Message.Location.spam
        let expirationTime: Date? = nil
        let isFrozenFalse = Int64.min
        let sut = MessageEntity.make(rawFlag: isFrozenFalse,
                                     expirationTime: expirationTime,
                                     labels: [LabelEntity.make(labelID: location.labelID)])
        XCTAssertFalse(sut.isAutoDeleting)
    }

    func testAutoDeletingMessageShouldBeFalseIfExpirationTimeIsFrozen() {
        let location = Message.Location.spam
        let expirationTime = Date()
        let isFrozenTrue = Int64.max
        let sut = MessageEntity.make(rawFlag: isFrozenTrue,
                                     expirationTime: expirationTime,
                                     labels: [LabelEntity.make(labelID: location.labelID)])
        XCTAssertFalse(sut.isAutoDeleting)
    }
}

// MARK: extend variables tests

extension MessageEntityTests {
    func testIsPlainText() {
        let message = Message(context: testContext)
        message.messageID = MessageID.generateLocalID().rawValue
        message.mimeType = "text/plain"
        var entity = MessageEntity(message)
        XCTAssertTrue(entity.isPlainText)
        XCTAssertEqual(message.isPlainText, entity.isPlainText)

        message.mimeType = "TEXT/PLAIN"
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isPlainText)
        XCTAssertEqual(message.isPlainText, entity.isPlainText)

        message.mimeType = "aifjld"
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isPlainText)
        XCTAssertEqual(message.isPlainText, entity.isPlainText)
    }

    func testIsMultipartMixed() {
        let message = Message(context: testContext)
        message.messageID = MessageID.generateLocalID().rawValue
        message.mimeType = "multipart/mixed"
        var entity = MessageEntity(message)
        XCTAssertTrue(entity.isMultipartMixed)

        message.mimeType = "MULTIPART/MIXED"
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isMultipartMixed)

        message.mimeType = "aifjld"
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isMultipartMixed)
    }

    func testMessageLocation() {
        let message = Message(context: testContext)
        message.messageID = MessageID.generateLocalID().rawValue
        let label1 = Label(context: testContext)
        label1.labelID = "1"
        label1.type = 3
        let label2 = Label(context: testContext)
        label2.labelID = "2"
        label2.type = 3
        let label3 = Label(context: testContext)
        label3.labelID = "sdjfisjfjdsofj"
        label3.type = 3

        var sut = MessageEntity(message)
        sut.setLabels([
            LabelEntity(label: label2),
            LabelEntity(label: label3),
            LabelEntity(label: label1)
        ])

        XCTAssertEqual(sut.messageLocation?.labelID.rawValue, label3.labelID)
    }

    func testOrderedLocation() {
        let message = Message(context: testContext)
        message.messageID = MessageID.generateLocalID().rawValue
        let label1 = Label(context: testContext)
        label1.labelID = "1"
        label1.type = 3
        let label2 = Label(context: testContext)
        label2.labelID = "2"
        label2.type = 3
        let label3 = Label(context: testContext)
        label3.labelID = "sdjfisjfjdsofj"
        label3.type = 3
        let label4 = Label(context: testContext)
        label4.labelID = "5"
        label4.type = 3
        let label5 = Label(context: testContext)
        label5.labelID = "10"
        label5.type = 3

        var sut = MessageEntity(message)
        sut.setLabels([
            LabelEntity(label: label4),
            LabelEntity(label: label5),
            LabelEntity(label: label2),
            LabelEntity(label: label3),
            LabelEntity(label: label1)
        ])

        XCTAssertEqual(sut.orderedLocation?.labelID.rawValue, label3.labelID)
    }

    func testOrderedLabel() {
        let message = Message(context: testContext)
        message.messageID = MessageID.generateLocalID().rawValue
        let label1 = Label(context: testContext)
        label1.labelID = "sdfpoapvmsnd"
        label1.order = NSNumber(1)
        label1.type = NSNumber(1)
        let label2 = Label(context: testContext)
        label2.labelID = "saonasinoaisfoiasfj"
        label2.order = NSNumber(2)
        label2.type = NSNumber(1)
        let label3 = Label(context: testContext)
        label3.labelID = "saonasinoaiasdasdsfoiasfj"
        label3.order = NSNumber(3)
        label3.type = NSNumber(2)

        var sut = MessageEntity(message)
        sut.setLabels([
            LabelEntity(label: label3),
            LabelEntity(label: label2),
            LabelEntity(label: label1)
        ])

        XCTAssertEqual(sut.orderedLabel,
                       [
                           LabelEntity(label: label1),
                           LabelEntity(label: label2)
                       ])
    }

    func testCustomFolder() {
        let message = Message(context: testContext)
        message.messageID = MessageID.generateLocalID().rawValue
        let label1 = Label(context: testContext)
        label1.labelID = "sdfpoapvmsnd"
        label1.order = NSNumber(1)
        label1.type = NSNumber(1)
        let label2 = Label(context: testContext)
        label2.labelID = "saonasinoaisfoiasfj"
        label2.order = NSNumber(2)
        label2.type = NSNumber(1)
        let label3 = Label(context: testContext)
        label3.labelID = "saonasinoaiasdasdsfoiasfj"
        label3.order = NSNumber(3)
        label3.type = NSNumber(3)

        var sut = MessageEntity(message)
        sut.setLabels([
            LabelEntity(label: label3),
            LabelEntity(label: label2),
            LabelEntity(label: label1)
        ])

        XCTAssertEqual(sut.customFolder, LabelEntity(label: label3))
    }

    func testIsCustomFolder() {
        let message = Message(context: testContext)
        message.messageID = MessageID.generateLocalID().rawValue
        let label1 = Label(context: testContext)
        label1.labelID = "sdfpoapvmsnd"
        label1.order = NSNumber(1)
        label1.type = NSNumber(1)
        let label2 = Label(context: testContext)
        label2.labelID = "saonasinoaisfoiasfj"
        label2.order = NSNumber(2)
        label2.type = NSNumber(1)
        let label3 = Label(context: testContext)
        label3.labelID = "saonasinoaiasdasdsfoiasfj"
        label3.order = NSNumber(3)
        label3.type = NSNumber(3)

        var sut = MessageEntity(message)
        sut.setLabels([
            LabelEntity(label: label3),
            LabelEntity(label: label2),
            LabelEntity(label: label1)
        ])

        XCTAssertTrue(sut.isCustomFolder)
    }

    func testIsScheduledSend() {
        let message = Message(context: testContext)
        message.messageID = MessageID.generateLocalID().rawValue
        message.flags = NSNumber(value: 1 << 20)

        let sut = MessageEntity(message)

        XCTAssertTrue(sut.isScheduledSend)
    }

    func testGetSenderImageRequestInfo_displaySenderImageIsTrue_returnInfo() throws {
        let address = "\(String.randomString(10))@pm.me"
        let bimiSelector = String.randomString(20)
        let isDarkMode = Bool.random()
        let rawSender = """
        {
        "Name": "",
        "Address": "\(address)",
        "IsProton": 0,
        "IsSimpleLogin": 0,
        "DisplaySenderImage": 1,
        "BimiSelector": "\(bimiSelector)"
        }
        """
        let sut = MessageEntity.make(rawSender: rawSender)

        let result = try XCTUnwrap(sut.getSenderImageRequestInfo(isDarkMode: isDarkMode))

        XCTAssertEqual(result.isDarkMode, isDarkMode)
        XCTAssertEqual(result.bimiSelector, bimiSelector)
        XCTAssertEqual(result.senderAddress, address)
    }

    func testGetSenderImageRequestInfo_displaySenderImageIsFalse_returnNil() throws {
        let rawSender = """
        {
        "Name": "",
        "Address": "\(String.randomString(20))",
        "IsProton": 0,
        "IsSimpleLogin": 0,
        "DisplaySenderImage": 0,
        "BimiSelector": "\(String.randomString(20))"
        }
        """
        let sut = MessageEntity.make(rawSender: rawSender)

        XCTAssertNil(sut.getSenderImageRequestInfo(isDarkMode: Bool.random()))
    }

    func testAttachmentsMetadataIsProperlyParsed() {
        let id = UUID().uuidString
        let name = String.randomString(Int.random(in: 0..<100))
        let size = Int.random(in: 0..<25_000_000)
        let mimeTypeString = "image/png"
        let disposition = Bool.random() ? "attachment" : "inline"
        let rawAttachmentsMetadata = """
        [
            {
                "ID": "\(id)",
                "Name": "\(name)",
                "Size": \(size),
                "MIMEType": "\(mimeTypeString)",
                "Disposition": "\(disposition)"
            }
        ]
        """
        let message = Message(context: testContext)
        message.attachmentsMetadata = rawAttachmentsMetadata
        let sut = MessageEntity(message)
        XCTAssertEqual(sut.attachmentsMetadata[0].id, id)
        XCTAssertEqual(sut.attachmentsMetadata[0].name, name)
        XCTAssertEqual(sut.attachmentsMetadata[0].size, size)
        XCTAssertEqual(sut.attachmentsMetadata[0].mimeType, mimeTypeString)
        XCTAssertEqual(sut.attachmentsMetadata[0].disposition.rawValue, disposition)
    }

}
