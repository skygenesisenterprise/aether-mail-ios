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

struct ContextLabelEntity: Equatable, Hashable {
    let messageCount: Int
    let unreadCount: Int
    let time: Date?
    let size: Int
    let attachmentCount: Int
    let conversationID: ConversationID
    let labelID: LabelID
    let userID: UserID
    let order: Int
    let objectID: ObjectID
    let expirationTime: Date?
    let snoozeTime: Date?

    let isSoftDeleted: Bool
}

extension ContextLabelEntity {
    init(_ contextLabel: ContextLabel) {
        self.messageCount = contextLabel.messageCount.intValue
        self.unreadCount = contextLabel.unreadCount.intValue
        self.time = contextLabel.time
        self.size = contextLabel.size.intValue
        self.attachmentCount = contextLabel.attachmentCount.intValue
        self.conversationID = ConversationID(contextLabel.conversationID)
        self.labelID = LabelID(contextLabel.labelID)
        self.userID = UserID(contextLabel.userID)
        self.order = contextLabel.order.intValue
        self.isSoftDeleted = contextLabel.isSoftDeleted
        self.objectID = ObjectID(rawValue: contextLabel.objectID)
        self.expirationTime = contextLabel.expirationTime
        self.snoozeTime = contextLabel.snoozeTime
    }

    static func convert(from conversation: Conversation) -> [ContextLabelEntity] {
        conversation.labels.allObjects.compactMap { item in
            guard let contextLabel = item as? ContextLabel else { return nil }
            return ContextLabelEntity(contextLabel)
        }
        .sorted(by: { $0.order < $1.order })
    }
}
