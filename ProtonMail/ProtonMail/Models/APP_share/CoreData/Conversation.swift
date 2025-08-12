//
//  Conversation.swift
//  Proton Mail
//
//
//  Copyright (c) 2020 Proton AG
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
import Foundation

final class Conversation: NSManagedObject {
    enum Attributes: String, CaseIterable {
        static let entityName = "Conversation"
        static let labels = "labels"

        case addressID = "addressID"
        case conversationID = "conversationID"
        case expirationTime = "expirationTime"
        case numAttachments = "numAttachments"
        case numMessages = "numMessages"
        case order = "order"
        case recipients = "recipients"
        case senders = "senders"
        case userID = "userID"
        case isSoftDeleted = "isSoftDeleted"
        case size = "size"
        case subject = "subject"
        case attachmentsMetadata = "attachmentsMetadata"
    }

    @NSManaged var conversationID: String
    @NSManaged var expirationTime: Date?

    @NSManaged var numAttachments: NSNumber
    @NSManaged var numMessages: NSNumber

    @NSManaged var order: NSNumber

    @NSManaged var senders: String
    @NSManaged var recipients: String
    /// Local use flag to mark this conversation is deleted
    /// (usually caused by empty trash/ spam action)
    @NSManaged var isSoftDeleted: Bool

    @NSManaged var size: NSNumber?
    @NSManaged var subject: String
    @NSManaged var labels: NSSet

    @NSManaged var userID: String

    @NSManaged var attachmentsMetadata: String

    @NSManaged var displaySnoozedReminder: Bool
}

extension Conversation {
    func getNumUnread(labelID: String) -> Int {
        guard let contextLabels = self.labels.allObjects as? [ContextLabel] else {
            return 0
        }
        let matchingLabel = contextLabels.filter { $0.labelID == labelID }.first
        guard let matched = matchingLabel else {
            return 0
        }
        return matched.unreadCount.intValue
    }

    func isUnread(labelID: String) -> Bool {
        return getNumUnread(labelID: labelID) != 0
    }

    func getTime(labelID: String) -> Date? {
        guard let contextLabels = self.labels.allObjects as? [ContextLabel] else {
            return nil
        }
        let matchingLabel = contextLabels.filter { $0.labelID == labelID }.first
        guard let matched = matchingLabel else {
            return nil
        }
        return matched.time
    }

    func contains(of labelID: String) -> Bool {
        guard let contextLabels = self.labels.allObjects as? [ContextLabel] else {
            return false
        }
        return contextLabels.contains { $0.labelID == labelID }
    }

    class func conversationForConversationID(_ conversationID: String, inManagedObjectContext context: NSManagedObjectContext) -> Conversation? {
        return context.managedObjectWithEntityName(Attributes.entityName,
                                                   forKey: Attributes.conversationID.rawValue,
                                                   matchingValue: conversationID) as? Conversation
    }

    class func conversationFor(_ conversationID: String, userID: UserID, in context: NSManagedObjectContext) -> Conversation? {
        return context.managedObjectWithEntityName(
            Attributes.entityName,
            matching: [
                Attributes.conversationID.rawValue: conversationID,
                Attributes.userID.rawValue: userID.rawValue
            ]
        )
    }

    func getContextLabel(location: LabelLocation) -> ContextLabel? {
        guard self.managedObjectContext != nil else { return nil }
        let contextLabels = self.labels.compactMap { $0 as? ContextLabel }
        return contextLabels.first(where: { $0.labelID == location.labelID.rawValue })
    }
}

// MARK: Apply local changes
extension Conversation {
    /// Apply single mark as changes for single message in conversation.
    func applySingleMarkAsChanges(unRead: Bool, labelID: String) {
        willChangeValue(forKey: Conversation.Attributes.labels)
        let labels = self.mutableSetValue(forKey: Conversation.Attributes.labels)
        let contextLabels = labels.compactMap { $0 as? ContextLabel }

        let labelsToUpdate = contextLabels.filter { $0.labelID == labelID || $0.labelID == Message.Location.allmail.rawValue }
        let offset = unRead ? 1: -1

        for label in labelsToUpdate {
            let newUnreadCount = max(label.unreadCount.intValue + offset, 0)
            label.unreadCount = NSNumber(value: newUnreadCount)
        }
        displaySnoozedReminder = false
        didChangeValue(forKey: Conversation.Attributes.labels)
    }

    /// Apply mark as changes to whole conversation.
    func applyMarksAsChanges(unRead: Bool, labelID: String, pushUpdater: PushUpdater) {
        let labels = self.mutableSetValue(forKey: Conversation.Attributes.labels)
        let contextLabels = labels.compactMap { $0 as? ContextLabel }
        let messages = Message
            .messagesForConversationID(self.conversationID,
                                       inManagedObjectContext: managedObjectContext!,
                                       shouldSort: true) ?? []

        var changedLabels: Set<String> = []
        if unRead {
            // It marks the latest message of the conversation of the current location (inbox, archive, etc...) as unread.
            if let message = messages
                .filter({ $0.contains(label: labelID)})
                .last {
                message.unRead = true
                if let messageLabels = message.labels.allObjects as? [Label] {
                    let changed = messageLabels.map { $0.labelID }
                    for id in changed {
                        changedLabels.insert(id)
                    }
                }
            }
        } else {
            // It marks the entire all messages attach to the conversation (Conversation.Messages) as read.
            for message in messages {
                guard message.unRead == true else { continue }
                message.unRead = false
                pushUpdater.remove(notificationIdentifiers: [message.notificationId])
                guard let messageLabels = message.labels.allObjects as? [Label] else { continue }
                let changed = messageLabels.map { $0.labelID }
                for id in changed {
                    changedLabels.insert(id)
                }
            }
        }

        for label in contextLabels where changedLabels.contains(label.labelID) || label.labelID == labelID {
            let offset = unRead ? 1: -1
            var unreadCount = label.unreadCount.intValue + offset
            unreadCount = max(unreadCount, 0)
            label.unreadCount = NSNumber(value: unreadCount)

            if let contextLabelInContext = ConversationCount
                .lastContextUpdate(by: label.labelID,
                                userID: self.userID,
                                inManagedObjectContext: managedObjectContext!) {
                contextLabelInContext.unread += Int32(offset)
                contextLabelInContext.unread = max(contextLabelInContext.unread, 0)
            }
        }
    }

    /// Apply label changes on one message of a conversation.
    func applyLabelChangesOnOneMessage(labelID: String, apply: Bool) {
        let labels = self.mutableSetValue(forKey: Conversation.Attributes.labels).compactMap { $0 as? ContextLabel }
        let hasLabel = labels.contains(where: { $0.labelID == labelID })
        let numMessages = labels.first(where: {$0.labelID == labelID})?.messageCount.intValue ?? 0

        if apply {
            if hasLabel {
                if let label = labels.first(where: {$0.labelID == labelID}) {
                    label.messageCount = NSNumber(value: numMessages + 1)
                } else {
                    fatalError()
                }
            } else {
                let newLabel = ContextLabel(context: self.managedObjectContext!)
                newLabel.labelID = labelID
                newLabel.messageCount = 1
                newLabel.time = Date()
                newLabel.userID = self.userID
                newLabel.size = self.size ?? NSNumber(value: 0)
                newLabel.attachmentCount = self.numAttachments
                newLabel.conversationID = self.conversationID
                newLabel.conversation = self
            }
        } else if hasLabel, let label = labels.first(where: {$0.labelID == labelID}) {
            if numMessages <= 1 {
                self.mutableSetValue(forKey: Conversation.Attributes.labels).remove(label)
            } else {
                label.messageCount = NSNumber(value: numMessages - 1)
            }
        }
    }

    /// Apply label changes of a conversation.
    func applyLabelChanges(labelID: String, apply: Bool) {
        if apply {
            if self.contains(of: labelID) {
                if let target = self.labels.compactMap({ $0 as? ContextLabel }).filter({ $0.labelID == labelID }).first {
                    target.messageCount = self.numMessages
                } else {
                    fatalError()
                }
            } else {
                let allMailLabel = self.getContextLabel(location: .allmail)
                let newLabel = ContextLabel(context: self.managedObjectContext!)
                newLabel.labelID = labelID
                newLabel.messageCount = self.numMessages
                newLabel.time = allMailLabel?.time ?? Date()
                newLabel.userID = self.userID
                newLabel.size = self.size ?? NSNumber(value: 0)
                newLabel.attachmentCount = self.numAttachments
                newLabel.conversationID = self.conversationID
                newLabel.conversation = self

                let messages = Message
                    .messagesForConversationID(self.conversationID,
                                               inManagedObjectContext: managedObjectContext!) ?? []
                newLabel.unreadCount = NSNumber(value: messages.filter { $0.unRead }.count)
            }
        } else {
            if self.contains(of: labelID), let label = labels.compactMap({ $0 as? ContextLabel }).filter({ $0.labelID == labelID }).first {
                self.mutableSetValue(forKey: Conversation.Attributes.labels).remove(label)
            }
        }
    }
}
