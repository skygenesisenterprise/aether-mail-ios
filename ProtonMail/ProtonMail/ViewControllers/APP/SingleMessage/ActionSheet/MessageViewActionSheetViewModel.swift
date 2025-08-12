//
//  MessageViewActionSheetViewModel.swift
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

struct MessageViewActionSheetViewModel: ActionSheetViewModel {
    let title: String
    private(set) var items: [MessageViewActionSheetAction] = []

    // swiftlint:disable:next function_body_length
    init(
        title: String,
        labelID: LabelID,
        isStarred: Bool,
        isBodyDecryptable: Bool,
        messageRenderStyle: MessageRenderStyle,
        shouldShowRenderModeOption: Bool,
        isScheduledSend: Bool,
        shouldShowSnooze: Bool
    ) {
        self.title = title

        if !isScheduledSend {
            items.append(.reply)
            items.append(.replyAll)
            items.append(.forward)
        }

        if shouldShowSnooze {
            items.append(.snooze)
        }

        items.append(contentsOf: [
            .markUnread,
            .labelAs,
            isStarred ? .unstar : .star
        ])

        if shouldShowRenderModeOption {
            switch messageRenderStyle {
            case .lightOnly:
                items.append(.viewInDarkMode)
            case .dark:
                items.append(.viewInLightMode)
            }
        }

        if labelID != Message.Location.trash.labelID {
            items.append(.trash)
        }

        if ![Message.Location.archive.labelID, Message.Location.spam.labelID].contains(labelID) {
            items.append(.archive)
        }

        if labelID == Message.Location.archive.labelID || labelID == Message.Location.trash.labelID {
            items.append(.inbox)
        }

        if labelID == Message.Location.spam.labelID {
            items.append(.spamMoveToInbox)
        }

        let foldersAllowingDeleteAction = [
            Message.Location.draft.labelID,
            Message.Location.sent.labelID,
            Message.Location.spam.labelID,
            Message.Location.trash.labelID
        ]
        if foldersAllowingDeleteAction.contains(labelID) {
            items.append(.delete)
        } else {
            items.append(.spam)
        }

        items.append(contentsOf: [
            .moveTo,
            .saveAsPDF,
            .print,
            .toolbarCustomization,
            .viewHeaders
        ])

        if isBodyDecryptable {
            items.append(.viewHTML)
        }

        items.append(.reportPhishing)
    }
}
