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

import Foundation
import ProtonCoreUIFoundations

struct ConversationEntity: Equatable, Hashable {
    let objectID: ObjectID
    let conversationID: ConversationID
    let expirationTime: Date?
    let attachmentCount: Int
    let messageCount: Int
    let order: Int
    let senders: String
    let recipients: String
    let size: Int?
    let subject: String
    let userID: UserID
    let contextLabelRelations: [ContextLabelEntity]
    let attachmentsMetadata: [AttachmentsMetadata]
    let displaySnoozedReminder: Bool

    /// Local use flag to mark this conversation is deleted
    /// (usually caused by empty trash/ spam action)
    let isSoftDeleted: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(conversationID)
        hasher.combine(objectID)
    }
}

extension ConversationEntity {
    init(_ conversation: Conversation) {
        self.objectID = ObjectID(rawValue: conversation.objectID)
        self.conversationID = ConversationID(conversation.conversationID)
        self.expirationTime = conversation.expirationTime
        self.attachmentCount = conversation.numAttachments.intValue
        self.messageCount = conversation.numMessages.intValue
        self.order = conversation.order.intValue
        self.senders = conversation.senders
        self.recipients = conversation.recipients
        self.size = conversation.size?.intValue
        self.subject = conversation.subject
        self.userID = UserID(conversation.userID)

        self.contextLabelRelations = ContextLabelEntity.convert(from: conversation)

        self.isSoftDeleted = conversation.isSoftDeleted
        let parsedAttachments: [AttachmentsMetadata]?
        do {
            parsedAttachments = try AttachmentsMetadata
                .decodeListOfDictionaries(jsonString: conversation.attachmentsMetadata)
        } catch {
            parsedAttachments = nil
            SystemLogger.log(error: error)
        }
        self.attachmentsMetadata = parsedAttachments ?? []
        self.displaySnoozedReminder = conversation.displaySnoozedReminder
    }

    var starred: Bool {
        return contains(of: .starred)
    }
}

extension ConversationEntity {
    func contains(of labelID: LabelID) -> Bool {
        return contextLabelRelations
            .contains(where: { $0.labelID == labelID })
    }

    func contains(of location: Message.Location) -> Bool {
        return contains(of: location.labelID)
    }

    func isUnread(labelID: LabelID) -> Bool {
        return getNumUnread(labelID: labelID) != 0
    }

    func getNumUnread(labelID: LabelID) -> Int {
        guard let matchedLabel = contextLabelRelations
                .first(where: { $0.labelID == labelID }) else {
            return 0
        }
        return matchedLabel.unreadCount
    }

    func getLabelIDs() -> [LabelID] {
        return contextLabelRelations.map(\.labelID)
    }

    func getTime(labelID: LabelID) -> Date? {
        guard let matchedLabel = contextLabelRelations
                .first(where: { $0.labelID == labelID }) else {
            return nil
        }
        return matchedLabel.time
    }

    func getSnoozeTime(labelID: LabelID) -> Date? {
        guard let matchedLabel = contextLabelRelations
            .first(where: { $0.labelID == labelID }) else {
            return nil
        }
        return matchedLabel.snoozeTime
    }

    func getFirstValidFolder() -> LabelID? {
        let foldersToFilter = [
            Message.HiddenLocation.sent.rawValue,
            Message.HiddenLocation.draft.rawValue,
            Message.Location.starred.rawValue,
            Message.Location.allmail.rawValue
        ]
        return getLabelIDs().first { labelID in
            labelID.rawValue.preg_match("(?!^\\d+$)^.+$") == false && !foldersToFilter.contains(labelID.rawValue)
        }
    }

    func getNumMessages(labelID: LabelID) -> Int {
        guard let matchedLabel = contextLabelRelations
                .first(where: { $0.labelID == labelID }) else {
            return 0
        }
        return matchedLabel.messageCount
    }

    func isExpiring() -> Bool {
        contextLabelRelations.contains(where: { contextLabelEntity in
            contextLabelEntity.expirationTime == expirationTime &&
            ( contextLabelEntity.labelID.rawValue == LabelLocation.trash.rawLabelID ||
              contextLabelEntity.labelID.rawValue == LabelLocation.spam.rawLabelID)
        }) == false
    }
}

// MARK: - Senders
extension ConversationEntity {
    func parseSenders() throws -> [Sender] {
        try Sender.decodeListOfDictionaries(jsonString: senders)
    }
}

extension ConversationEntity {
    #if !APP_EXTENSION
    // swiftlint:disable:next function_body_length
    func getFolderIcons(customFolderLabels: [LabelEntity]) -> [ImageAsset.Image] {
        let labelIds = getLabelIDs()
        let standardFolders: [LabelID] = [
            Message.Location.inbox,
            Message.Location.trash,
            Message.Location.spam,
            Message.Location.archive,
            Message.Location.sent,
            Message.Location.draft
        ].map({ $0.labelID })

        // Display order: Inbox, Custom, Drafts, Sent, Archive, Spam, Trash
        let standardFolderWithOrder: [Message.Location: Int] = [
            .inbox: 0,
            .draft: 2,
            .sent: 3,
            .archive: 4,
            .spam: 5,
            .trash: 6
        ]

        let customLabelIdsMap = customFolderLabels.reduce([:]) { result, label -> [LabelID: LabelEntity] in
            var newValue = result
            newValue[label.labelID] = label
            return newValue
        }

        var addedDict: [ImageAsset.Image: Bool] = [:]
        let filteredLabelIds = labelIds.filter { labelId in
            return (customLabelIdsMap[labelId] != nil) || standardFolders.contains(labelId)
        }

        let sortedLabelIds = filteredLabelIds.sorted { labelId1, labelId2 in
            var orderOfLabelId1 = Int.max
            if let location = Message.Location(labelId1) {
                orderOfLabelId1 = standardFolderWithOrder[location] ?? Int.max
            } else {
                orderOfLabelId1 = 1
            }

            var orderOfLabelId2 = Int.max
            if let location = Message.Location(labelId2) {
                orderOfLabelId2 = standardFolderWithOrder[location] ?? Int.max
            } else {
                orderOfLabelId2 = 1
            }

            return orderOfLabelId1 < orderOfLabelId2
        }

        var isCustomFolderIconAdded = false
        return Array(sortedLabelIds.compactMap { lableId in
            var icon: ImageAsset.Image?
            if standardFolders.contains(lableId) {
                if let location = Message.Location(lableId) {
                    icon = location.originImage()
                }
            } else if !isCustomFolderIconAdded {
                isCustomFolderIconAdded = true
                icon = IconProvider.folder
            }
            if let iconToAdd = icon,
               addedDict.updateValue(true, forKey: iconToAdd) == nil { // filter duplicated icon
                return iconToAdd
            } else {
                return nil
            }
        }.prefix(3))
    }

    func getSenderImageRequestInfo(isDarkMode: Bool) -> SenderImageRequestInfo? {
        guard let sender = try? parseSenders().first, sender.shouldDisplaySenderImage else {
            return nil
        }

        return .init(
            bimiSelector: sender.bimiSelector,
            senderAddress: sender.address,
            isDarkMode: isDarkMode
        )
    }
    #endif
}
