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

@testable import ProtonMail
import XCTest

final class ContactDeleteRequestTests: XCTestCase {
    func testInit_withNonUUIDIds_returnNonNil() throws {
        let id = String.randomString(50)

        let sut = try XCTUnwrap(ContactDeleteRequest(ids: [id]))

        XCTAssertEqual(sut.contactIDs, [id])
    }

    func testInit_withUUIDIds_returnNil() throws {
        let id = UUID().uuidString

        XCTAssertNil(ContactDeleteRequest(ids: [id]))
    }

    func testInit_withEmptyInput_returnNil() throws {
        XCTAssertNil(ContactDeleteRequest(ids: []))
    }
}
