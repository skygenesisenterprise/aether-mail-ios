//
//  MailboxViewController+BuildMessageViewModel.swift
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

import UIKit

extension MailboxViewController {

    private func attachmentsPreviews(for mailboxItem: MailboxItem) -> [AttachmentPreviewViewModel] {
        viewModel.previewableAttachments(for: mailboxItem).map {
            AttachmentPreviewViewModel(
                name: $0.name,
                icon: AttachmentType(mimeType: $0.mimeType.lowercased()).icon
            )
        }
    }

    func buildNewMailboxMessageViewModel(
        message: MessageEntity,
        customFolderLabels: [LabelEntity],
        weekStart: WeekStart,
        canSelectMore: Bool
    ) -> NewMailboxMessageViewModel {
        let labelId = viewModel.labelID
        let isSelected = self.viewModel.selectionContains(id: message.messageID.rawValue)
        let contactGroups = viewModel.contactGroups()
        var senderRowComponents = mailboxMessageCellHelper.senderRowComponents(
            for: message,
            basedOn: replacingEmailsMap,
            groupContacts: contactGroups,
            shouldReplaceSenderWithRecipients: true
        )
        if senderRowComponents.isEmpty {
            senderRowComponents = [.string("")]
        }
        let isSending = viewModel.messageService.isMessageBeingSent(id: message.messageID)

        var initial = "?"
        if let firstSenderRowComponent = senderRowComponents.first {
            initial = [firstSenderRowComponent].initials()
        }

        let style: NewMailboxMessageViewStyle = message.contains(location: .scheduled) ? .scheduled : .normal
        var mailboxViewModel = NewMailboxMessageViewModel(
            location: Message.Location(viewModel.labelID),
            isLabelLocation: message.isLabelLocation(labelId: labelId),
            style: viewModel.listEditing ? .selection(isSelected: isSelected, isAbleToBeSelected: canSelectMore) : style,
            initial: initial,
            isRead: !message.unRead,
            sender: senderRowComponents,
            time: isSending ? LocalString._mailbox_draft_is_sending : date(of: message, weekStart: weekStart),
            isForwarded: message.isForwarded,
            isReply: message.isReplied,
            isReplyAll: message.isRepliedAll,
            topic: message.title,
            isStarred: message.isStarred,
            hasAttachment: message.numAttachments > 0,
            tags: message.createTags(),
            messageCount: 0,
            folderIcons: [],
            scheduledTime: message.contains(location: .scheduled) ? dateForScheduled(of: message) : nil,
            isScheduledTimeInNext10Mins: checkIsDateWillHappenInTheNext10Mins(of: message),
            attachmentsPreviewViewModels: attachmentsPreviews(for: .message(message)),
            numberOfAttachments: message.numAttachments,
            hasSnoozeLabel: message.contains(location: .snooze),
            snoozeTime: dateForSnoozeTime(of: message),
            hasShowReminderFlag: message.showReminder,
            reminderTime: dateForReminder(of: message, weekStart: weekStart)
        )
        let displayOriginIcon = [
            Message.Location.allmail,
            Message.Location.starred,
            Message.Location.almostAllMail
        ].contains(Message.Location(viewModel.labelID))
        if displayOriginIcon || mailboxViewModel.isLabelLocation {
            mailboxViewModel.folderIcons = message.getFolderIcons(customFolderLabels: customFolderLabels)
        }

        let isTrashed = message.contains(labelID: Message.Location.trash.labelID)

        if (message.isDraft || message.isSent) && isTrashed,
           let icon = Message.Location.trash.originImage() {
            mailboxViewModel.folderIcons.append(icon)
        }
        return mailboxViewModel
    }

    func buildNewMailboxMessageViewModel(
        conversation: ConversationEntity,
        conversationTagUIModels: [TagUIModel],
        customFolderLabels: [LabelEntity],
        weekStart: WeekStart,
        canSelectMore: Bool
    ) -> NewMailboxMessageViewModel {
        let labelId = viewModel.labelID
        let isSelected = self.viewModel.selectionContains(id: conversation.conversationID.rawValue)
        let senderRowComponents = mailboxMessageCellHelper.senderRowComponents(
            for: conversation,
            basedOn: replacingEmailsMap
        )
        let messageCount = conversation.messageCount
        let isInCustomFolder = customFolderLabels.map({ $0.labelID }).contains(labelId)
        let isHavingScheduled = conversation.contains(of: Message.Location.scheduled)

        var initial = ""
        if let firstSenderRowComponent = senderRowComponents.first {
            initial = [firstSenderRowComponent].initials()
        }

        var mailboxViewModel = NewMailboxMessageViewModel(
            location: Message.Location(viewModel.labelID),
            isLabelLocation: Message.Location(viewModel.labelId) == nil && !isInCustomFolder,
            style: viewModel.listEditing ? .selection(isSelected: isSelected, isAbleToBeSelected: canSelectMore) : .normal,
            initial: initial,
            isRead: conversation.getNumUnread(labelID: labelId) <= 0,
            sender: senderRowComponents,
            time: date(of: conversation, labelId: labelId, weekStart: weekStart),
            isForwarded: false,
            isReply: false,
            isReplyAll: false,
            topic: conversation.subject,
            isStarred: conversation.starred,
            hasAttachment: conversation.attachmentCount > 0,
            tags: conversationTagUIModels,
            messageCount: messageCount > 0 ? messageCount : 0,
            folderIcons: [],
            scheduledTime: isHavingScheduled ? dateForScheduled(of: conversation) : nil,
            isScheduledTimeInNext10Mins: checkIsDateWillHappenInTheNext10Mins(of: conversation),
            attachmentsPreviewViewModels: attachmentsPreviews(for: .conversation(conversation)),
            numberOfAttachments: conversation.attachmentCount,
            hasSnoozeLabel: conversation.contains(of: Message.Location.snooze.labelID),
            snoozeTime: dateForSnoozeTime(of: conversation),
            hasShowReminderFlag: conversation.displaySnoozedReminder,
            reminderTime: dateForReminder(of: conversation, weekStart: weekStart)
        )
        let displayOriginIcon = [
            Message.Location.allmail,
            Message.Location.starred,
            Message.Location.almostAllMail
        ].contains(Message.Location(viewModel.labelID))
        if displayOriginIcon || mailboxViewModel.isLabelLocation {
            mailboxViewModel.folderIcons = conversation.getFolderIcons(customFolderLabels: customFolderLabels)
        }
        return mailboxViewModel
    }

    private func date(of message: MessageEntity, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

    private func date(of conversation: ConversationEntity, labelId: LabelID, weekStart: WeekStart) -> String {
        guard let date = conversation.getTime(labelID: labelId) else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

    private func dateForScheduled(of message: MessageEntity) -> String? {
        guard message.contains(location: .scheduled),
              let date = message.time else { return nil }
        return PMDateFormatter.shared.stringForScheduledMsg(from: date, inListView: true)
    }

    private func dateForScheduled(of conversation: ConversationEntity) -> String? {
        guard let date = conversation.getTime(labelID: Message.Location.scheduled.labelID) else { return nil }
        return PMDateFormatter.shared.stringForScheduledMsg(from: date, inListView: true)
    }

    private func checkIsDateWillHappenInTheNext10Mins(of conversation: ConversationEntity) -> Bool {
        guard let date = conversation.getTime(labelID: Message.Location.scheduled.labelID) else { return false }
        return PMDateFormatter.shared.checkIsDateWillHappenInTheNext10Mins(date)
    }

    private func checkIsDateWillHappenInTheNext10Mins(of message: MessageEntity) -> Bool {
        guard message.contains(location: .scheduled),
              let date = message.time else { return false }
        return PMDateFormatter.shared.checkIsDateWillHappenInTheNext10Mins(date)
    }

    private func dateForSnoozeTime(of message: MessageEntity) -> String? {
        guard message.contains(location: .snooze), let date = message.snoozeTime else {
            return nil
        }
        return PMDateFormatter.shared.stringForSnoozeTime(from: date)
    }

    private func dateForSnoozeTime(of conversation: ConversationEntity) -> String? {
        guard let date = conversation.getSnoozeTime(labelID: Message.Location.snooze.labelID) else {
            return nil
        }
        return PMDateFormatter.shared.stringForSnoozeTime(from: date)
    }

    private func dateForReminder(of message: MessageEntity, weekStart: WeekStart) -> String? {
        guard let date = message.snoozeTime else { return nil }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

    private func dateForReminder(
        of conversation: ConversationEntity,
        weekStart: WeekStart
    ) -> String? {
        guard let date = conversation.getSnoozeTime(labelID: Message.Location.inbox.labelID) else { return nil }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }
}
