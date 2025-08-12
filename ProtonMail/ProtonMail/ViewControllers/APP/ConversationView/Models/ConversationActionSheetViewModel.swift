//
//  ConversationActionSheetViewModel.swift
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
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreDataModel

struct ConversationActionSheetViewModel: ActionSheetViewModel {
    let title: String
    private(set) var items: [MessageViewActionSheetAction] = []

    init(
        title: String,
        isUnread: Bool,
        isStarred: Bool,
        isScheduleSend: Bool,
        isSupportSnooze: Bool,
        areAllMessagesIn: (LabelLocation) -> Bool
    ) {
        self.title = title

        if !isScheduleSend {
            items.append(.reply)
            items.append(.replyAll)
            items.append(.forward)
        }

        items.append(isUnread ? .markRead : .markUnread)
        if isSupportSnooze {
            items.append(.snooze)
        }
        items.append(isStarred ? .unstar : .star)
        items.append(.labelAs)

        if areAllMessagesIn(.trash) || areAllMessagesIn(.draft) || areAllMessagesIn(.sent) {
            items.append(contentsOf: [.inbox, .archive, .delete, .moveTo])
        } else if areAllMessagesIn(.archive) {
            items.append(contentsOf: [.trash, .inbox, .spam, .moveTo])
        } else if areAllMessagesIn(.spam) {
            items.append(contentsOf: [.trash, .spamMoveToInbox, .delete, .moveTo])
        } else {
            items.append(contentsOf: [.trash, .archive, .spam, .moveTo])
        }

        items.append(contentsOf: [
            .saveAsPDF,
            .print,
            .toolbarCustomization,
            .viewHeaders,
            .viewHTML,
            .reportPhishing
        ])
    }
}
