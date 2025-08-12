//
//  StorefrontCoordinatorTests.swift
//  Proton Mail
//
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
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

@testable import ProtonMail
import XCTest

class StorefrontCoordinatorTests: XCTestCase {

    var sut: StorefrontCoordinator!
    var sideMenuMock: MockSideMenuProtocol!

    override func setUp() {
        super.setUp()

        sideMenuMock = MockSideMenuProtocol()
        sut = StorefrontCoordinator(
            paymentsUI: MockPaymentsUIProtocol(),
            sideMenu: sideMenuMock,
            eventsService: EventsServiceMock()
        )
    }

    override func tearDown() {
        super.tearDown()

        sideMenuMock = nil
        sut = nil
    }

    func testCoordinatorStart() {
        sut.start()

        XCTAssertEqual(sideMenuMock.hideMenuStub.callCounter, 1)
        XCTAssertEqual(sideMenuMock.hideMenuStub.arguments(forCallCounter: 1)?.a1, true)

        XCTAssertEqual(sideMenuMock.setContentViewControllerStub.callCounter, 1)
        XCTAssertEqual(sideMenuMock.setContentViewControllerStub.arguments(forCallCounter: 1)?.a2, false)

        let presentedViewController = sideMenuMock.setContentViewControllerStub.arguments(forCallCounter: 1)?.a1

        XCTAssertTrue(presentedViewController is UINavigationController)

        let navigationController = presentedViewController as? UINavigationController

        XCTAssertTrue(navigationController?.viewControllers.first is StorefrontViewController)
    }

}
