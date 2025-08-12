//
//  ConversationDataService+CollectionFetching.swift
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

import Foundation
import Groot

// MARK: - Collection fetching
extension ConversationDataService {
    func fetchConversationCounts(addressID: String?, completion: ((Result<Void, Error>) -> Void)?) {
        let conversationCountRequest = ConversationCountRequest(addressID: addressID)
        self.apiService.perform(request: conversationCountRequest) { _, result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
            case .success(let response):
                let countDict = response["Counts"] as? [[String: Any]]
                self.eventsService?.processEvents(conversationCounts: countDict)
                DispatchQueue.main.async {
                    completion?(.success(()))
                }
            }
        }
    }

    @available(*, deprecated, message: "Prefer the async variant")
    func fetchConversations(for labelID: LabelID,
                            before timestamp: Int,
                            unreadOnly: Bool,
                            shouldReset: Bool,
                            completion: (@Sendable (Result<Void, Error>) -> Void)?) {
        ConcurrencyUtils.runWithCompletion(
            block: fetchConversations,
            arguments: (labelID, timestamp, unreadOnly, shouldReset),
            completion: completion
        )
    }

    func fetchConversations(for labelID: LabelID,
                            before timestamp: Int,
                            unreadOnly: Bool,
                            shouldReset: Bool) async throws {
        var para = ConversationsRequest.Parameters()
        if timestamp > 0 {
            para.end = timestamp - 1
        }
        if unreadOnly {
            para.unread = 1
        }
        para.limit = 50
        para.sort = labelID == Message.Location.snooze.labelID ? "SnoozeTime" : "Time"
        if labelID == Message.Location.snooze.labelID || labelID == Message.Location.scheduled.labelID {
            para.desc = 0
        } else {
            para.desc = 1
        }
        para.labelID = labelID.rawValue

        let request = ConversationsRequest(para)

        let responseDict: JSONDictionary = try await apiService.perform(request: request).1
        let response = ConversationsResponse()
        guard response.ParseResponse(responseDict) else {
            throw NSError.protonMailError(1000, localizedDescription: "Parsing error")
        }
        if shouldReset {
            self.cleanAll()
            self.lastUpdatedStore.removeUpdateTimeExceptUnread(by: self.userID)
            self.userDefaults[.areContactsCached] = 0
        }
        let totalMessageCount = responseDict["Total"] as? Int ?? 0
        var conversationsDict = response.conversationsDict

        for index in conversationsDict.indices {
            conversationsDict[index]["UserID"] = self.userID.rawValue
            let conversationID = conversationsDict[index]["ID"]
            if var labels = conversationsDict[index]["Labels"] as? [[String: Any]] {
                for index in labels.indices {
                    labels[index]["UserID"] = self.userID.rawValue
                    labels[index]["ConversationID"] = conversationID
                }
                conversationsDict[index]["Labels"] = labels
            }
        }

        let conversationsTimeRange: (startTime: Date, endTime: Date?)? = try contextProvider.write { context in
            if let conversations = try GRTJSONSerialization.objects(
                withEntityName: Conversation.Attributes.entityName,
                fromJSONArray: conversationsDict,
                in: context
            ) as? [Conversation] {
                for conversation in conversations {
                    if let labels = conversation.labels as? Set<ContextLabel> {
                        for label in labels {
                            label.order = conversation.order
                        }
                    }
                    self.modifyNumMessageIfNeeded(conversation: conversation)
                }

                if let error = context.saveUpstreamIfNeeded() {
                    throw error
                } else if let lastConversation = conversations.last, let firstConversation = conversations.first {
                    let startTime = firstConversation.getTime(labelID: labelID.rawValue) ?? Date()
                    let endTime = lastConversation.getTime(labelID: labelID.rawValue)
                    return (startTime, endTime)
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }

        if let (startTime, endTime) = conversationsTimeRange {
            self.lastUpdatedStore.updateLastUpdatedTime(
                labelID: labelID,
                isUnread: unreadOnly,
                startTime: startTime,
                endTime: endTime,
                msgCount: totalMessageCount,
                userID: self.userID,
                type: .conversation
            )
        }
    }

    func modifyNumMessageIfNeeded(conversation: Conversation) {
        guard conversation.isSoftDeleted else { return }
        var spamNum: Int = 0
        if let spamLabel = conversation.getContextLabel(location: .spam) {
            spamNum = spamLabel.messageCount.intValue
        }
        var trashNum: Int = 0
        if let trashLabel = conversation.getContextLabel(location: .trash) {
            trashNum = trashLabel.messageCount.intValue
        }
        let numMessage = conversation.numMessages.intValue - spamNum - trashNum
        conversation.numMessages = NSNumber(value: numMessage)
    }

    func softDeleteMessageIfNeeded(conversation: Conversation, messages: [Message]) {
        let messages = messages.filter { $0.conversationID == conversation.conversationID }
        guard conversation.isSoftDeleted,
              !messages.isEmpty else { return }
        if let _ = conversation.getContextLabel(location: .spam) {
            self.softDelete(messages: messages, location: .spam)
        }
        if let _ = conversation.getContextLabel(location: .trash) {
            self.softDelete(messages: messages, location: .trash)
        }
    }

    private func softDelete(messages: [Message], location: Message.Location) {
        messages
            .filter { message in
                let label = message.labels
                    .compactMap { $0 as? Label }
                    .map(\.labelID)
                    .compactMap(Message.Location.init)
                    .first(where: { $0 != .allmail && $0 != .starred })
                return label == location
            }
            .forEach { $0.isSoftDeleted = true }
    }

    func fetchConversations(with conversationIDs: [ConversationID], completion: ((Result<Void, Error>) -> Void)?) {
        var para = ConversationsRequest.Parameters()
        para.IDs = conversationIDs.map(\.rawValue)
        
        let request = ConversationsRequest(para)
        self.apiService.perform(request: request) { _, result in
            switch result {
            case .failure(let err):
                DispatchQueue.main.async {
                    completion?(.failure(err))
                }
            case .success(let responseDict):
                let response = ConversationsResponse()
                guard response.ParseResponse(responseDict) else {
                    let err = NSError.protonMailError(1000, localizedDescription: "Parsing error")
                    DispatchQueue.main.async {
                        completion?(.failure(err))
                    }
                    return
                }
                
                self.contextProvider.performOnRootSavingContext { context in
                    do {
                        var conversationsDict = response.conversationsDict

                        guard !conversationsDict.isEmpty else {
                            DispatchQueue.main.async {
                                completion?(.failure(NSError.protonMailError(1000, localizedDescription: "Data not found")))
                            }
                            return
                        }

                        for index in conversationsDict.indices {
                            conversationsDict[index]["UserID"] = self.userID.rawValue
                            let conversationID = conversationsDict[index]["ID"]
                            if var labels = conversationsDict[index]["Labels"] as? [[String: Any]] {
                                for (index, _) in labels.enumerated() {
                                    labels[index]["UserID"] = self.userID.rawValue
                                    labels[index]["ConversationID"] = conversationID
                                }
                                conversationsDict[index]["Labels"] = labels
                            }
                        }

                        if let conversations = try GRTJSONSerialization.objects(withEntityName: Conversation.Attributes.entityName, fromJSONArray: conversationsDict, in: context) as? [Conversation] {
                            for conversation in conversations {
                                if let labels = conversation.labels as? Set<ContextLabel> {
                                    for label in labels {
                                        label.order = conversation.order
                                    }
                                }
                            }
                            _ = context.saveUpstreamIfNeeded()
                        }
                        DispatchQueue.main.async {
                            completion?(.success(()))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion?(.failure(error as NSError))
                        }
                    }
                }
            }
        }
    }
}
