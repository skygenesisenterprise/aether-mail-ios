// Copyright (c) 2022 Proton Technologies AG
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
@testable import ProtonMail

final class ContactCombineViewModelTests: XCTestCase {
    private var sut: ContactCombineViewModel!
    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        userDefaults = TestContainer().userDefaults
        sut = ContactCombineViewModel(userDefaults: userDefaults)
    }

    override func tearDownWithError() throws {
        sut = nil
        userDefaults = nil
    }

    func testBasicData() throws {
        XCTAssertEqual(sut.output.title, LocalString._combined_contacts)
        XCTAssertEqual(sut.output.sectionNumber, 1)
        XCTAssertEqual(sut.output.rowNumber, 1)
        XCTAssertEqual(sut.output.headerTopPadding, 8)
        XCTAssertEqual(sut.output.footerTopPadding, 8)

        for i in 0...3 {
            let indexPath = IndexPath(row: i, section: 0)
            let item = try XCTUnwrap(sut.output.cellData(for: indexPath))
            XCTAssertEqual(item.title, L10n.SettingsContacts.combinedContacts)
            XCTAssertEqual(item.status, userDefaults[.isCombineContactOn])
        }

        XCTAssertNil(sut.output.sectionHeader())
        let footer = try XCTUnwrap(sut.output.sectionFooter(section: 0))
        switch footer {
        case .left(let text):
            XCTAssertEqual(text, L10n.SettingsContacts.combinedContactsFooter)
        case .right(_):
            XCTFail("Should be a string")
        }

    }

    func testToggle() throws {
        userDefaults[.isCombineContactOn] = false
        let indexPath = IndexPath(row: 0, section: 0)
        let expectation1 = expectation(description: "closure is called")
        sut.input.toggle(for: indexPath, to: true) { error in
            XCTAssertNil(error)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1)
        XCTAssertTrue(userDefaults[.isCombineContactOn])

        let expectation2 = expectation(description: "closure is called")
        sut.input.toggle(for: indexPath, to: false) { error in
            XCTAssertNil(error)
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1)
        XCTAssertFalse(userDefaults[.isCombineContactOn])
    }

}
