// Copyright (c) 2021 Proton AG
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

class MenuViewControllerUnitTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCalcProperMenuWidth_windowWiderThanMenuExpected() throws {
        let widenKeyWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 480, height: 500))
        let expectedMenuWidth: CGFloat = 327
        let calcWidth = MenuViewController.calcProperMenuWidth(keyWindow: widenKeyWindow,
                                                               referenceWidth: nil,
                                                               expectedMenuWidth: expectedMenuWidth)
        XCTAssertEqual(expectedMenuWidth, calcWidth)
    }

    func testCalcProperMenuWidth_windowNarrowerThanMenuExpected() {
        let windowWidth: CGFloat = 300
        let expectedMenuWidth: CGFloat = 327
        let narrowKeyWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: windowWidth, height: 500))
        let calcWidth = MenuViewController.calcProperMenuWidth(keyWindow: narrowKeyWindow,
                                                               referenceWidth: nil,
                                                               expectedMenuWidth: expectedMenuWidth)
        XCTAssertEqual(windowWidth, calcWidth)
    }

    func testCalcProperMenuWidth_viewSizeBecomeWider() {
        let windowWidth: CGFloat = 300
        let expectedMenuWidth: CGFloat = 327
        let newViewWidth: CGFloat = 400
        let narrowKeyWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: windowWidth, height: 500))
        let calcWidth = MenuViewController.calcProperMenuWidth(keyWindow: narrowKeyWindow,
                                                               referenceWidth: newViewWidth,
                                                               expectedMenuWidth: expectedMenuWidth)
        XCTAssertEqual(expectedMenuWidth, calcWidth)
    }

    func testCalcProperMenuWidth_viewSizeBecomeNarrower() {
        let expectedMenuWidth: CGFloat = 327
        let newViewWidth: CGFloat = 300
        let widenKeyWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 480, height: 500))
        let calcWidth = MenuViewController.calcProperMenuWidth(keyWindow: widenKeyWindow,
                                                               referenceWidth: newViewWidth,
                                                               expectedMenuWidth: expectedMenuWidth)
        XCTAssertEqual(newViewWidth, calcWidth)
    }
}
