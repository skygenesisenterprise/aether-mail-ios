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

import Groot
@testable import ProtonMail
import XCTest

final class PurgeOldMessagesTests: XCTestCase {
    private var sut: PurgeOldMessages!
    private var coreDataService: MockCoreDataContextProvider!
    private var mockFetchMessageMetaDataUC: MockFetchMessageMetaData!
    private var userID: UserID!

    override func setUp() {
        self.userID = UserID(UUID().uuidString)
        self.coreDataService = MockCoreDataContextProvider()
        self.mockFetchMessageMetaDataUC = MockFetchMessageMetaData()
        self.sut = PurgeOldMessages(
            dependencies: .init(coreDataService: self.coreDataService,
                                fetchMessageMetaData: self.mockFetchMessageMetaDataUC,
                                userID: userID))
    }

    override func tearDown() {
        self.userID = nil
        self.coreDataService = nil
        self.mockFetchMessageMetaDataUC = nil
        self.sut = nil
    }

    // All messages contains meta data
    func testZeroMessagesCase() throws {
        let expectation = expectation(description: "callbacks are called")
        self.sut.execute(params: ()) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        let messageIDs = try XCTUnwrap(self.mockFetchMessageMetaDataUC.messageIDs.first)
        XCTAssertEqual(messageIDs.count, 0)
    }

    func testMessagesWithoutMetaDataCase() throws {
        var parsedObject = try XCTUnwrap(testMessageMetaData.parseObjectAny())
        parsedObject["UserID"] = self.userID.rawValue
        let messageID = MessageID(UUID().uuidString)
        parsedObject["ID"] = messageID.rawValue

        try coreDataService.performAndWaitOnRootSavingContext { context in
            let testMessage = try GRTJSONSerialization.object(withEntityName: "Message",
                                                              fromJSONDictionary: parsedObject, in: context) as? Message
            testMessage?.messageStatus = NSNumber(value: 0)
            try context.save()
        }

        let expectation = expectation(description: "callbacks are called")
        self.sut.execute(params: ()) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        let messageIDs = try XCTUnwrap(self.mockFetchMessageMetaDataUC.messageIDs.first)
        XCTAssertEqual(messageIDs.count, 1)
        XCTAssertEqual(messageIDs.first, messageID)
    }
}
