//
//  EventAPITests.swift
//  ProtonMailTests - Created on 2020.
//
//
//  Copyright (c) 2020 Proton AG
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

@testable import ProtonMail
import XCTest

class EventAPITests: XCTestCase {
    func testEventCheckResponseParsing() throws {
        let data = eventTestDatawithDeleteConversation.data(using: .utf8)!
        let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]

        let sut = EventCheckResponse()
        XCTAssertTrue(sut.ParseResponse(responseDictionary))

        XCTAssertEqual(sut.eventID, "YavOMCsY_G_OM2ti21cBlKbY-wVO-LaxvvLwGFM5duj3RpswhVBMFkepPg==")
        XCTAssertEqual(RefreshStatus(rawValue: sut.refresh), .ok)
        XCTAssertEqual(sut.more, 0)
        XCTAssertEqual(sut.messages?.count, 3)

        XCTAssertNil(sut.contacts)
        XCTAssertNil(sut.contactEmails)
        XCTAssertNil(sut.labels)
        XCTAssertNil(sut.user)
        XCTAssertNil(sut.userSettings)
        XCTAssertNil(sut.mailSettings)
        XCTAssertNil(sut.addresses)
        XCTAssertEqual(sut.messageCounts?.count, 11)

        XCTAssertEqual(sut.conversations?.count, 1)

        XCTAssertEqual(sut.conversationCounts?.count, 11)

        XCTAssertEqual(sut.usedSpace, 157621062)
        XCTAssertEqual(sut.notices, [])
    }

    func testEventCheckRequestUrlPath_whenDiscardContactsMetadataIsFalse() {
        let eventID = String.randomString(20)
        let sut = EventCheckRequest(eventID: eventID, discardContactsMetadata: false)

        XCTAssertEqual(
            sut.path,
            "/core/v5/events/\(eventID)?ConversationCounts=1&MessageCounts=1"
        )
    }

    func testEventCheckRequestUrlPath_whenDiscardContactsMetadataIsTrue() {
        let eventID = String.randomString(20)
        let sut = EventCheckRequest(eventID: eventID, discardContactsMetadata: true)

        XCTAssertEqual(
            sut.path,
            "/core/v5/events/\(eventID)?ConversationCounts=1&MessageCounts=1&NoMetaData%5B%5D=Contact"
        )
    }
}
