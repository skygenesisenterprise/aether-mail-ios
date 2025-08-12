//
//  CacheServiceTests+UnreadCounter.swift
//  ProtonMailTests
//
//  Copyright (c) 2021 Proton AG
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

import CoreData
@testable import ProtonMail
import XCTest

extension CacheServiceTest {
    func testUpdateCounterSyncOnMessage() {
        let labelIDs: [LabelID] = self.testMessage.getLabelIDs().map(LabelID.init(rawValue:))

        for label in labelIDs {
            loadTestDataOfUnreadCount(defaultUnreadCount: 1, labelID: label)
        }

        sut.updateCounterSync(markUnRead: false, on: labelIDs)

        for label in labelIDs {
            let msgUnReadCount: Int = lastUpdatedStore.unreadCount(by: label, userID: sut.userID, type: .singleMessage)
            XCTAssertEqual(msgUnReadCount, 0)

            let conversationUnReadCount: Int = lastUpdatedStore.unreadCount(by: label, userID: sut.userID, type: .conversation)
            XCTAssertEqual(conversationUnReadCount, 0)
        }
    }

    func testMinusUnreadOnMessageWithWrongUnreadData() {
        let labelIDs: [LabelID] = self.testMessage.getLabelIDs().map(LabelID.init(rawValue:))

        for label in labelIDs {
            loadTestDataOfUnreadCount(defaultUnreadCount: 0, labelID: label)
        }

        sut.updateCounterSync(markUnRead: false, on: labelIDs)

        for label in labelIDs {
            let msgUnReadCount: Int = lastUpdatedStore.unreadCount(by: label, userID: sut.userID, type: .singleMessage)
            XCTAssertEqual(msgUnReadCount, 0)

            let conversationUnReadCount: Int = lastUpdatedStore.unreadCount(by: label, userID: sut.userID, type: .conversation)
            XCTAssertEqual(conversationUnReadCount, 0)
        }
    }

    func testPlusUnreadOnOneLabel() {
        loadTestDataOfUnreadCount(defaultUnreadCount: 1, labelID: "0")

        sut.updateCounterSync(plus: true, with: "0")

        let msgCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(msgCount, 2)

        let conversationCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .conversation)
        XCTAssertEqual(conversationCount, 2)
    }

    func testMinusUnreadOnOneLabel() {
        loadTestDataOfUnreadCount(defaultUnreadCount: 1, labelID: "0")

        sut.updateCounterSync(plus: false, with: "0")

        let msgCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(msgCount, 0)

        let conversationCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .conversation)
        XCTAssertEqual(conversationCount, 0)
    }

    func testMinusUnreadOnLabelWithZeroUnread() {
        loadTestDataOfUnreadCount(defaultUnreadCount: 0, labelID: "0")

        sut.updateCounterSync(plus: false, with: "0")

        let msgCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(msgCount, 0)

        let conversationCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .conversation)
        XCTAssertEqual(conversationCount, 0)
    }

    func testDeleteSoftDeleteOnAttachment() throws {
        let attID = "attID"
        let attachment = Attachment(context: testContext)
        attachment.attachmentID = attID
        attachment.fileName = "filename"
        attachment.mimeType = "image"
        attachment.fileData = nil
        attachment.fileSize = 1
        attachment.isTemp = false
        attachment.keyPacket = ""
        attachment.localURL = nil
        attachment.message = testMessage
        _ = testContext.saveUpstreamIfNeeded()

        let expect = expectation(description: "attachment delete completion")
        sut.delete(attachment: AttachmentEntity(attachment)) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        let att = Attachment.attachment(for: attID, inManagedObjectContext: testContext)
        let unwarpAtt = try XCTUnwrap(att)
        XCTAssertTrue(unwarpAtt.isSoftDeleted)
    }
}

private extension Attachment {
    class func attachment(for attID: String, inManagedObjectContext context: NSManagedObjectContext) -> Attachment? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.attachmentID, matchingValue: attID) as? Attachment
    }
}
