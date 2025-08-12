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
import ProtonCoreCrypto
import GoLibs

@testable import ProtonMail

class CardDataParserTests: XCTestCase {
    private var sut: CardDataParser!
    private let email = "emaile@aaa.bbb"

    override func setUpWithError() throws {
        try super.setUpWithError()

        let userPrivateKey = ContactParserTestData.privateKey
        sut = CardDataParser(userKeys: [userPrivateKey])
    }

    override func tearDownWithError() throws {
        sut = nil

        try super.tearDownWithError()
    }

    func testParsesCorrectContactWithValidSignature() throws {
        let cardData = CardData(
            type: .SignedOnly,
            data: ContactParserTestData.signedOnlyData,
            signature: ContactParserTestData.signedOnlySignature
        )

        let parsed = try XCTUnwrap(sut.verifyAndParseContact(with: email, from: [cardData]))
        XCTAssertEqual(parsed.email, email)
        XCTAssertEqual(parsed.sign, .signingFlagNotFound)
    }

    func testVerifyAndParseContact_withPMSignIsTrue_signFlagIsParsed() throws {
        let signature = try Sign.signDetached(
            signingKey: .init(
                privateKey: ContactParserTestData.privateKey,
                passphrase: ContactParserTestData.passphrase
            ),
            plainText: ContactParserTestData.signedOnlyDataWithPMSignTrue
        )
        let cardData = CardData(
            type: .SignedOnly,
            data: ContactParserTestData.signedOnlyDataWithPMSignTrue,
            signature: signature
        )

        let parsed = try XCTUnwrap(
            sut.verifyAndParseContact(with: email, from: [cardData])
        )

        XCTAssertEqual(parsed.email, email)
        XCTAssertEqual(parsed.sign, .sign)
    }

    func testVerifyAndParseContact_withPMSignIsFalse_signFlagIsParsed() throws {
        let signature = try Sign.signDetached(
            signingKey: .init(
                privateKey: ContactParserTestData.privateKey,
                passphrase: ContactParserTestData.passphrase
            ),
            plainText: ContactParserTestData.signedOnlyDataWithPMSignFalse
        )
        let cardData = CardData(
            type: .SignedOnly,
            data: ContactParserTestData.signedOnlyDataWithPMSignFalse,
            signature: signature
        )

        let parsed = try XCTUnwrap(
            sut.verifyAndParseContact(with: email, from: [cardData])
        )

        XCTAssertEqual(parsed.email, email)
        XCTAssertEqual(parsed.sign, .doNotSign)
    }

    func testRejectsCorrectContactIfSignatureIsInvalid() {
        let cardData = CardData(
            type: .SignedOnly,
            data: ContactParserTestData.signedOnlyData,
            signature: "invalid signature"
        )

        XCTAssertNil(sut.verifyAndParseContact(with: email, from: [cardData]))
    }

    func testIgnoresCardDataTypesOtherThanSignedOnly() {
        let ignoredTypes: [CardDataType] = [.PlainText, .EncryptedOnly, .SignAndEncrypt]
        let unhandledCards = ignoredTypes.map {
            CardData(
                type: $0,
                data: ContactParserTestData.signedOnlyData,
                signature: ContactParserTestData.signedOnlySignature
            )
        }

        XCTAssertNil(sut.verifyAndParseContact(with: email, from: unhandledCards))
    }
}
