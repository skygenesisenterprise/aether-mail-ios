//
//  CacheServiceTests+Contact.swift
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
    func testAddNewContact() throws {
        var objectID: NSManagedObjectID?
        contextProviderMock.performAndWaitOnRootSavingContext { context in
            let tempContact = Contact(context: context)
            try? context.save()
            try? context.obtainPermanentIDs(for: [tempContact])
            objectID = tempContact.objectID
        }
        let contactData = testSingleContactData.parseJson()!
        let expect = expectation(description: "Add contact")

        sut.addNewContact(
            serverResponse: contactData,
            localContactsURIs: [objectID!.uriRepresentation().absoluteString]
        ) { _ in
            expect.fulfill()
        }

        wait(for: [expect], timeout: 1)
        let contactToCheck = try XCTUnwrap(Contact.contactForContactID("_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg==", inManagedObjectContext: testContext))
        XCTAssertEqual(contactToCheck.contactID, "_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg==")
        XCTAssertEqual(contactToCheck.name, "Test")
        XCTAssertEqual(contactToCheck.emails.count, 1)
        XCTAssertEqual(contactToCheck.userID, sut.userID.rawValue)
        XCTAssertEqual(contactToCheck.cardData, "[{\"Data\":\"BEGIN:VCARD\\r\\nVERSION:4.0\\r\\nPRODID:pm-ez-vcard 0.0.1\\r\\nUID:protonmail-ios-8260FE2E-B019-4B18-B901-787F95131063\\r\\nFN:Test\\r\\nItem1.EMAIL;TYPE=:test@test.com\\r\\nEND:VCARD\\r\\n\",\"Type\":2,\"Signature\":\"-----BEGIN PGP SIGNATURE-----\\nVersion: GopenPGP 2.1.3\\nComment: https:\\/\\/gopenpgp.org\\n\\nwsBzBAABCgAnBQJgOySzCRBWRx+SquDI6BYhBH1iPl3sKPKRrnFgC1ZHH5Kq4Mjo\\nAADgYAgA3XXJ88i\\/AMxL1OZpx\\/fB\\/WTXalqzLmKq7TUrQienSLs8v9t32mbzpWqP\\nmqsQV9FHKNSOvGTSZ8nsQy6tZtFZfK5gE2m2fK8o+1brCVE3g4oACJ1mHoI4JatC\\ncpAgR4EXN4Dw3glwzNvLs\\/Ly2Oj99gNjORAI3kvpW655b9av+jKWA94Dn661ZMFd\\nicCJV43XhgDcYn0zrYkgOIZXR2awdMuGcQNqC65tkaBkE1OIMF0cJ43u5ugKnGkd\\ncm8LqiLW+cvpqev+59kBnAng2XpbbBnA3SxepbpQUdxegOimatW0pWsM2c+Vn3kU\\nbfB2elX7xAXdTI5bnYYQoqeqyIozJw==\\n=95OA\\n-----END PGP SIGNATURE-----\"}]")
        XCTAssertEqual(contactToCheck.size, 162)

        // Check if the temporary contact is deleted or not.
        contextProviderMock.performAndWaitOnRootSavingContext { context in
            if let objectID = objectID {
                let object = context.object(with: objectID)
                XCTAssertTrue(object.isFault)
            }
        }
    }

    func testUpdateContact() throws {
        // Load data
        let contactData = testSingleContactData.parseJson()!
        let expect = expectation(description: "Add contact")
        sut.addNewContact(serverResponse: contactData) { _ in
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        let contactToUpdate = try XCTUnwrap(Contact.contactForContactID("_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg==", inManagedObjectContext: testContext))

        XCTAssertEqual(contactToUpdate.name, "Test")

        var contactDict = testUpdatedContactData.parseObjectAny()!
        contactDict["Cards"] = testUpdatedContactCardData.parseJson()!

        let updateExpect = expectation(description: "Update Contact")
        sut.updateContact(contactID: ContactID(contactToUpdate.contactID), cardsJson: contactDict) { error in
            if let error = error {
                XCTFail("\(error)")
            }

            updateExpect.fulfill()
        }
        wait(for: [updateExpect], timeout: 1)

        XCTAssertEqual(contactToUpdate.name, "New Test")
    }

    func testDeleteContact() throws {
        // Load data
        let contactID = "_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg=="
        let contactData = testSingleContactData.parseJson()!
        let expect = expectation(description: "Add contact")
        sut.addNewContact(serverResponse: contactData) { _ in
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        XCTAssertNotNil(Contact.contactForContactID(contactID, inManagedObjectContext: testContext))

        let deleteExpect = expectation(description: "Delete contact")
        sut.deleteContact(by: ContactID(contactID), completion: { _ in
            deleteExpect.fulfill()
        })
        wait(for: [deleteExpect], timeout: 1)

        XCTAssertNil(Contact.contactForContactID(contactID, inManagedObjectContext: testContext))
    }

    func testUpdateContactDetail() throws {
        // Load data
        let contactID = "_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg=="
        let contactData = testSingleContactData.parseJson()!
        let expect = expectation(description: "Add contact")
        sut.addNewContact(serverResponse: contactData) { _ in
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)
        XCTAssertNotNil(Contact.contactForContactID(contactID, inManagedObjectContext: testContext))

        let contactDetailObject = testContactDetailData.parseObjectAny()!
        let contact = try sut.updateContactDetail(serverResponse: contactDetailObject)
        XCTAssertTrue(contact.isDownloaded)
        XCTAssertTrue(contact.isCorrected)
    }
}
