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

@testable import ProtonMail
import XCTest

class ConversationActionSheetViewModelTests: XCTestCase {
    private var dummyTitle: String { String.randomString(100) }

    private let expectedForAllInTrashDraftOrSent: [MessageViewActionSheetAction] = [.inbox, .archive, .delete, .moveTo, .saveAsPDF, .print, .toolbarCustomization, .viewHeaders, .viewHTML, .reportPhishing]
    private let expectedForAllInArchive: [MessageViewActionSheetAction] = [.trash, .inbox, .spam, .moveTo, .saveAsPDF, .print, .toolbarCustomization, .viewHeaders, .viewHTML, .reportPhishing]
    private let expectedForAllInSpam: [MessageViewActionSheetAction] = [.trash, .spamMoveToInbox, .delete, .moveTo, .saveAsPDF, .print, .toolbarCustomization, .viewHeaders, .viewHTML, .reportPhishing]
    private let expectedForMessInDifferentFolders: [MessageViewActionSheetAction] = [.trash, .archive, .spam, .moveTo, .saveAsPDF, .print, .toolbarCustomization, .viewHeaders, .viewHTML, .reportPhishing]

    func testInit_isScheduleSend_hasNotReplyAndForwardActions() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()

        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            isScheduleSend: true, 
            isSupportSnooze: false,
            areAllMessagesIn: { _ in irrelevantForTheTest }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssertFalse(sut.items.contains(.replyInConversation))
        XCTAssertFalse(sut.items.contains(.reply))
        XCTAssertFalse(sut.items.contains(.forwardInConversation))
        XCTAssertFalse(sut.items.contains(.forward))
    }

    func testInit_whenActionsAreUnreadAndStarred() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: true,
            isStarred: true,
            isScheduleSend: false, 
            isSupportSnooze: true,
            areAllMessagesIn: { _ in irrelevantForTheTest }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssertEqual(
            Array(sut.items.prefix(6)),
            [
                .reply,
                .replyAll,
                .forward,
                .markRead,
                .snooze,
                .unstar
            ]
        )
    }

    func testInit_whenActionsAreReadAndStarred() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: false,
            isStarred: true,
            isScheduleSend: false, 
            isSupportSnooze: true,
            areAllMessagesIn: { _ in irrelevantForTheTest }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssertEqual(
            Array(sut.items.prefix(6)),
            [
                .reply,
                .replyAll,
                .forward,
                .markUnread,
                .snooze,
                .unstar
            ]
        )
    }

    func testInit_whenActionsAreUnreadAndNotStarred() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: true,
            isStarred: false,
            isScheduleSend: false, 
            isSupportSnooze: true,
            areAllMessagesIn: { _ in irrelevantForTheTest }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssertEqual(
            Array(sut.items.prefix(6)),
            [
                .reply,
                .replyAll,
                .forward,
                .markRead,
                .snooze,
                .star
            ]
        )
    }

    func testInit_whenActionsAreReadAndNotStarred() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: false,
            isStarred: false,
            isScheduleSend: false, 
            isSupportSnooze: false,
            areAllMessagesIn: { _ in irrelevantForTheTest }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssertEqual(
            Array(sut.items.prefix(6)),
            [
                .reply,
                .replyAll,
                .forward,
                .markUnread,
                .star,
                .labelAs
            ]
        )
    }

    func testInit_whenAllMessagesAreLocatedInInbox() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            isScheduleSend: false,
            isSupportSnooze: false,
            areAllMessagesIn: { location in location == .inbox }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(10)) == expectedForMessInDifferentFolders)
    }

    func testInit_whenAllMessagesAreLocatedInTrash() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            isScheduleSend: false,
            isSupportSnooze: false,
            areAllMessagesIn: { location in location == .trash }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(10)) == expectedForAllInTrashDraftOrSent)
    }

    func testInit_whenAllMessagesAreLocatedInDraft() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            isScheduleSend: false, 
            isSupportSnooze: false,
            areAllMessagesIn: { location in location == .draft }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(10)) == expectedForAllInTrashDraftOrSent)
    }

    func testInit_whenAllMessagesAreLocatedInSent() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            isScheduleSend: false, 
            isSupportSnooze: false,
            areAllMessagesIn: { location in location == .sent }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(10)) == expectedForAllInTrashDraftOrSent)
    }

    func testInit_whenAllMessagesAreLocatedInArchive() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            isScheduleSend: false,
            isSupportSnooze: false,
            areAllMessagesIn: { location in location == .archive }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(10)) == expectedForAllInArchive)
    }

    func testInit_whenAllMessagesAreLocatedInSpam() {
        let title = dummyTitle
        let irrelevantForTheTest = Bool.random()
        let sut = ConversationActionSheetViewModel(
            title: title,
            isUnread: irrelevantForTheTest,
            isStarred: irrelevantForTheTest,
            isScheduleSend: false,
            isSupportSnooze: false,
            areAllMessagesIn: { location in location == .spam }
        )

        XCTAssertEqual(sut.title, title)
        XCTAssert(Array(sut.items.suffix(10)) == expectedForAllInSpam)
    }
}
