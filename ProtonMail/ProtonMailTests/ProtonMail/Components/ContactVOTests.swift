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

import ProtonCoreDataModel
import XCTest
@testable import ProtonMail

final class ContactVOTests: XCTestCase {
    func testIsDuplicated() {
        let contact1 = ContactVO(name: "name1", email: "mail1@test.com")
        let contact2 = ContactVO(name: "name2", email: "mail2@test.com")
        let address = Address(addressID: "", domainID: "test.com", email: "mail9@test.com", send: .active, receive: .active, status: .enabled, type: .protonAlias, order: 1, displayName: "", signature: "", hasKeys: 0, keys: [])
        let address1 = Address(addressID: "", domainID: "test.com", email: "mail1@test.com", send: .active, receive: .active, status: .enabled, type: .protonAlias, order: 1, displayName: "", signature: "", hasKeys: 0, keys: [])
        XCTAssertTrue(contact1.isDuplicated([address, address1]))
        XCTAssertFalse(contact2.isDuplicated([address, address1]))
    }

    func testExists() {
        let contact1 = ContactVO(name: "name1", email: "mail1@test.com")
        let contact2 = ContactVO(name: "name2", email: "mail2@test.com")

        XCTAssertTrue(contact1.exists(in:[contact1, contact2]))
        XCTAssertFalse(contact2.exists(in:[contact1]))
    }

    func testGetNameInContacts() {
        let contact1 = ContactVO(name: "name1", email: "mail1@test.com")
        let contact2 = ContactVO(name: "name2", email: "mail1@test.com")
        let contact3 = ContactVO(name: "name3", email: "mail3@test.com")
        let contact4 = ContactVO(name: "mail4@test.com", email: "mail4@test.com")
        let contact5 = ContactVO(name: "mail1@test.com", email: "mail1@test.com")

        XCTAssertEqual(contact4.getName(in: [contact1]), nil)
        XCTAssertEqual(contact3.getName(in: [contact1]), "name3")
        XCTAssertEqual(contact2.getName(in: [contact1]), "name1")
        XCTAssertEqual(contact1.getName(in: [contact5]), nil)
    }

    func testExtractMailAddress() {
        var value = "abc@test.com"
        var (name, address) = ContactVO.extractMailAddress(from: value)
        XCTAssertEqual(name, "abc@test.com")
        XCTAssertEqual(address, "abc@test.com")

        value = "John Smith <john.smith@example.org>"
        (name, address) = ContactVO.extractMailAddress(from: value)
        XCTAssertEqual(name, "John Smith")
        XCTAssertEqual(address, "john.smith@example.org")

        value = "John Smith <sayHi>"
        (name, address) = ContactVO.extractMailAddress(from: value)
        XCTAssertEqual(name, "John Smith <sayHi>")
        XCTAssertEqual(address, "John Smith <sayHi>")

        value = "\"💫 aaa | tester at protonmail.com\" <abcde@simplelogin.co>"
        (name, address) = ContactVO.extractMailAddress(from: value)
        XCTAssertEqual(name, "\"💫 aaa | tester at protonmail.com\"")
        XCTAssertEqual(address, "abcde@simplelogin.co")
    }
}
