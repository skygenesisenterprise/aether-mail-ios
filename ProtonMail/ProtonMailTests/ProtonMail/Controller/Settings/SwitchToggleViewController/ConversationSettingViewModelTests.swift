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

final class ConversationSettingViewModelTests: XCTestCase {
    private var sut: ConversationSettingViewModel!
    private var conversationStateProviderMock: MockConversationStateProviderProtocol!
    private var eventServiceMock: EventsServiceMock!
    private var viewModeUpdaterMock: MockViewModeUpdater!

    override func setUpWithError() throws {
        conversationStateProviderMock = MockConversationStateProviderProtocol()
        eventServiceMock = EventsServiceMock()
        viewModeUpdaterMock = MockViewModeUpdater()
        sut = ConversationSettingViewModel(
            updateViewModeService: viewModeUpdaterMock,
            conversationStateService: conversationStateProviderMock,
            eventService: eventServiceMock
        )
    }

    override func tearDownWithError() throws {
        conversationStateProviderMock = nil
        eventServiceMock = nil
        viewModeUpdaterMock = nil
        sut = nil
    }

    func testExample() throws {
        XCTAssertEqual(sut.output.title, LocalString._conversation_settings_title)
        XCTAssertEqual(sut.output.sectionNumber, 1)
        XCTAssertEqual(sut.output.rowNumber, 1)
        XCTAssertEqual(sut.output.headerTopPadding, 8)
        XCTAssertEqual(sut.output.footerTopPadding, 8)

        conversationStateProviderMock.viewModeStub.fixture = .conversation
        let indexPath = IndexPath(row: 0, section: 0)
        var item = try XCTUnwrap(sut.output.cellData(for: indexPath))
        XCTAssertEqual(item.title, LocalString._conversation_settings_row_title)
        XCTAssertEqual(item.status, true)

        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        item = try XCTUnwrap(sut.output.cellData(for: indexPath))
        XCTAssertEqual(item.status, false)

        XCTAssertNil(sut.output.sectionHeader())
        let footer = try XCTUnwrap(sut.output.sectionFooter(section: 0))
        switch footer {
        case .left(let text):
            XCTAssertEqual(text, LocalString._conversation_settings_footer_title)
        case .right(_):
            XCTFail("Should be a text type")
        }

    }

    func testToggle_disable() throws {
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        viewModeUpdaterMock.updateStub.bodyIs { _, newViewMode, completion in
            completion?(.success(newViewMode))
        }
        let indexPath = IndexPath(row: 0, section: 0)
        let expectation1 = expectation(description: "closure is called")
        sut.input.toggle(for: indexPath, to: false) { error in
            XCTAssertNil(error)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2)
        XCTAssertEqual(conversationStateProviderMock.viewModeStub.setCallCounter, 1)
        XCTAssertEqual(conversationStateProviderMock.viewModeStub.setLastArguments?.value, .singleMessage)
        XCTAssertEqual(viewModeUpdaterMock.updateStub.callCounter, 1)
        XCTAssertEqual(eventServiceMock.callFetchEvents.callCounter, 1)
    }

    func testToggle_enable() throws {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        viewModeUpdaterMock.updateStub.bodyIs { _, newViewMode, completion in
            completion?(.success(newViewMode))
        }
        let indexPath = IndexPath(row: 0, section: 0)
        let expectation1 = expectation(description: "closure is called")
        sut.input.toggle(for: indexPath, to: true) { error in
            XCTAssertNil(error)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2)
        XCTAssertEqual(conversationStateProviderMock.viewModeStub.setCallCounter, 1)
        XCTAssertEqual(conversationStateProviderMock.viewModeStub.setLastArguments?.value, .conversation)
        XCTAssertEqual(viewModeUpdaterMock.updateStub.callCounter, 1)
        XCTAssertEqual(eventServiceMock.callFetchEvents.callCounter, 1)
    }

    func testToggle_enable_failure() throws {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        viewModeUpdaterMock.updateStub.bodyIs { _, newViewMode, completion in
            let error = NSError(domain: "test.com", code: -99, localizedDescription: "update conversation failed")
            completion?(.failure(error))
        }
        let indexPath = IndexPath(row: 0, section: 0)
        let expectation1 = expectation(description: "closure is called")
        sut.input.toggle(for: indexPath, to: true) { error in
            XCTAssertEqual(error?.code, -99)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2)
        XCTAssertEqual(conversationStateProviderMock.viewModeStub.setCallCounter, 0)
        XCTAssertEqual(viewModeUpdaterMock.updateStub.callCounter, 1)
        XCTAssertEqual(eventServiceMock.callFetchEvents.callCounter, 0)
    }

    func testToggle_noUpdate() throws {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        viewModeUpdaterMock.updateStub.bodyIs { _, newViewMode, completion in
            completion?(.success(newViewMode))
        }
        let indexPath = IndexPath(row: 0, section: 0)
        let expectation1 = expectation(description: "closure is called")
        sut.input.toggle(for: indexPath, to: false) { error in
            XCTAssertNil(error)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2)
        XCTAssertEqual(conversationStateProviderMock.viewModeStub.setCallCounter, 0)
        XCTAssertEqual(viewModeUpdaterMock.updateStub.callCounter, 0)
        XCTAssertEqual(eventServiceMock.callFetchEvents.callCounter, 0)
    }
}
