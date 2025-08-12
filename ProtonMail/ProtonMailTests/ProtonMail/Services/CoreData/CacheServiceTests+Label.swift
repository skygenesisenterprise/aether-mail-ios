//
//  CacheServiceTests+Label.swift
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

import XCTest
@testable import ProtonMail

extension CacheServiceTest {

    func testAddLabel() throws {
        let labelID = "fFECHlO7rfi9KXhmx_CAKS32uaGGZgOy4Wgdpme4yg95zA4vUomxViDJmUYvrYGH51Mk0-wSs1m_A7IJHEA5tA=="
        let labelJson = testSingleLabelData.parseObjectAny()!

        let expect = expectation(description: "Add New label")
        sut.addNewLabel(serverResponse: labelJson) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        let labelToCheck = try XCTUnwrap(Label.labelForLabelID(labelID, inManagedObjectContext: testContext))
        XCTAssertEqual(labelToCheck.labelID, labelID)
        XCTAssertEqual(labelToCheck.userID, sut.userID.rawValue)
        XCTAssertEqual(labelToCheck.color, "#c26cc7")
        XCTAssertEqual(labelToCheck.name, "new")
        XCTAssertEqual(labelToCheck.type, 1)
    }
}
