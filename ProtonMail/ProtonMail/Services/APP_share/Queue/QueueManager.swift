//
//  QueueManager.swift
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
#if !APP_EXTENSION
import LifetimeTracker
#endif

protocol QueueHandler {
    var userID: UserID { get }
    func handleTask(_ task: QueueManager.Task, completion: @escaping (QueueManager.Task, QueueManager.TaskResult) -> Void)
}

// sourcery: mock
protocol QueueHandlerRegister {
    func registerHandler(_ handler: QueueHandler)
    func unregisterHandler(for userID: UserID, completion: (() -> Void)?)
}

/// This manager is used to handle the queue operations of all users.
final class QueueManager: QueueHandlerRegister {

    enum QueueStatus {
        case idle
        case running
    }

    typealias ReadBlock = (() -> Void)
    typealias TaskID = UUID

    private let queue = DispatchQueue(label: "Protonmail.QueueManager.Queue")

    /// Handle send message related things
    private let messageQueue: PMPersistentQueueProtocol
    /// Handle actions exclude sending message related things
    private let miscQueue: PMPersistentQueueProtocol
    private let internetStatusProvider = InternetConnectionStatusProvider.shared
    private var connectionStatus: ConnectionStatus? {
        willSet {
            guard
                let previousStatus = connectionStatus,
                let nextStatus = newValue,
                handlers.count > 0
            else { return }
            if previousStatus.isConnected == false && nextStatus.isConnected {
                // connection is back
                dequeueIfNeeded()
            }
        }
    }
    /// Handle the fetching data related things
    private var readQueue: [ReadBlock] = []
    private var handlers: [UserID: QueueHandler] = [:]
    private var hasDequeued = false

    // These two variables are used to prevent concurrent call of dequeue=
    private var isMessageRunning: Bool = false
    private var isMiscRunning: Bool = false
    // The remaining background executing time closure
    private var backgroundTimeRemaining: (() -> TimeInterval)?

    // A block will be called when exceed allowed background execute time
    private var exceedNotify: (() -> Void)?

    init(messageQueue: PMPersistentQueueProtocol,
         miscQueue: PMPersistentQueueProtocol) {
        self.messageQueue = messageQueue
        self.miscQueue = miscQueue

        internetStatusProvider.register(receiver: self)
        #if !APP_EXTENSION
        trackLifetime()
        #endif
    }

    func addTask(_ task: Task, autoExecute: Bool = true, completion: ((Bool) -> Void)? = nil) {
        queue.async {
            guard !task.userID.rawValue.isEmpty else {
                completion?(false)
                return
            }
            let action = task.action
            switch action {
            case .saveDraft, .send:
                let dependencies = self.getMessageTasks(of: task.userID)
                    .filter { $0.messageID == task.messageID }
                    .map(\.uuid)
                task.dependencyIDs = dependencies
                _ = self.messageQueue.add(task.uuid, object: task)
            case .uploadAtt, .deleteAtt, .uploadPubkey, .updateAttKeyPacket:
                _ = self.messageQueue.add(task.uuid, object: task)
            case .read, .unread,
                 .delete,
                 .emptyTrash, .emptySpam, .empty,
                 .label, .unlabel, .folder,
                 .updateLabel, .createLabel, .deleteLabel,
                 .updateContact, .deleteContact, .addContact, .addContacts,
                 .addContactGroup, .updateContactGroup, .deleteContactGroup,
                 .fetchContactDetail, .notificationAction, .blockSender, .unblockSender,
                 .unsnooze, .snooze:
                _ = self.miscQueue.add(task.uuid, object: task)
            case .signout:
                self.handleSignout(signoutTask: task)
            case .signin:
                self.handleSignin(userID: task.userID)
            case .fetchMessageDetail:
                break
            }
            if autoExecute {
                self.dequeueIfNeeded()
            }
            completion?(true)
        }
    }

    func queue(_ readBlock: @escaping ReadBlock) {
        self.queue.async {
            self.readQueue.append(readBlock)
            self.dequeueIfNeeded()
        }
    }

    // MARK: Queue handler
    func registerHandler(_ handler: QueueHandler) {
        self.queue.async {
            self.handlers[handler.userID] = handler
        }
    }

    func unregisterHandler(for userID: UserID, completion: (() -> Void)?) {
        self.queue.async {
            _ = self.handlers.removeValue(forKey: userID)
            completion?()
        }
    }

    // MARK: Background

    /// Claim the app enter the background
    /// - Parameters:
    ///   - remainingTime: The closure that can get the remaining background time of the system
    ///   - notify: Execute when all of tasks finish or the time is running out
    func backgroundFetch(remainingTime: (() -> TimeInterval)?, notify: @escaping (() -> Void)) {
        self.queue.async {
            self.backgroundTimeRemaining = remainingTime
            self.exceedNotify = notify
            self.dequeueIfNeeded()
        }
    }

    func enterForeground() {
        self.queue.async {
            self.backgroundTimeRemaining = nil
            self.dequeueIfNeeded()
        }
    }

    // MARK: Queue operations
    func removeAllTasks(of msgID: String, removalCondition: @escaping ((MessageAction) -> Bool), completeHandler: (() -> Void)?) {
        self.queue.async {
            let targetTasks = self.getMessageTasks(of: nil).filter { (task) -> Bool in
                task.messageID == msgID && removalCondition(task.action)
            }
            targetTasks.forEach { (task) in
                _ = self.messageQueue.remove(task.uuid)
            }
            completeHandler?()
        }
    }

    func isAnyQueuedMessage(of userID: UserID) -> Bool {
        self.queue.sync {
            let messageTasks = self.getMessageTasks(of: userID)
            let miscTasks = self.getMiscTasks(of: userID)
            let allTasks = messageTasks + miscTasks
            return allTasks.count > 0
        }
    }

    func deleteAllQueuedMessage(of userID: UserID, completeHander: (() -> Void)?) {
        self.queue.async {
            self.getMessageTasks(of: userID)
                .forEach { _ = self.messageQueue.remove($0.uuid)}

            self.getMiscTasks(of: userID)
                .forEach { _ = self.miscQueue.remove($0.uuid)}

            completeHander?()
        }
    }

    func queuedMessageIds() -> Set<String> {
        self.queue.sync {
            let allTasks = self.getMessageTasks(of: nil)
            return Set(allTasks.map(\.messageID))
        }
    }

    func clearAll() async {
        await withCheckedContinuation { continuation in
            self.queue.async {
                self.messageQueue.clearAll()
                self.miscQueue.clearAll()
                continuation.resume()
            }
        }
    }

    func messageIDsOfTasks(where actionPredicate: (MessageAction) -> Bool) -> [String] {
        self.queue.sync {
            self.getMessageTasks(of: nil)
                .filter { actionPredicate($0.action) }
                .map(\.messageID)
        }
    }
}

// MARK: Private functions
extension QueueManager {
    private func getTasks(from queue: PMPersistentQueueProtocol, userID: UserID?) -> [Task] {
        let allTasks = queue.queueArray().tasks
        if let id = userID {
            return allTasks.filter { $0.userID == id }
        } else {
            return allTasks
        }
    }

    private func getMessageTasks(of userID: UserID?) -> [Task] {
        return self.getTasks(from: self.messageQueue, userID: userID)
    }

    private func getMiscTasks(of userID: UserID?) -> [Task] {
        return self.getTasks(from: self.miscQueue, userID: userID)
    }

    private func handleSignout(signoutTask: Task) {
        /*
         1. Remove all of tasks that triggered by the user
         2. Insert the task to the begining of the queue

         What if the first task is from the user?
         There are two condition
         1. Online: Even the task removed from the queue, it still doing HTTP request
         2. Offline: The first task won't be executed, safely remove.

         Why insert to 0?
         1. Online: The previous keep running, insert to 0 will be the next task to execute.
         2. Offline: The first task is not running, safely insert.
         */

        self.getMessageTasks(of: signoutTask.userID)
            .forEach { _ = self.messageQueue.remove($0.uuid) }
        _ = self.messageQueue.insert(uuid: signoutTask.uuid, object: signoutTask, index: 0)

        self.getMiscTasks(of: signoutTask.userID)
            .forEach { _ = self.miscQueue.remove($0.uuid) }
        _ = self.miscQueue.insert(uuid: signoutTask.uuid, object: signoutTask, index: 0)
    }

    private func handleSignin(userID: UserID) {
        if let task = self.getMessageTasks(of: userID)
            .first(where: { $0.action == MessageAction.signout &&
                    $0.userID == userID }) {
            _ = self.messageQueue.remove(task.uuid)
        }

        if let task = self.getMiscTasks(of: userID)
            .first(where: { $0.action == MessageAction.signout &&
                    $0.userID == userID }) {
            _ = self.miscQueue.remove(task.uuid)
        }
    }

    /// Do notify if all of queues are empty
    /// - Returns: Any tasks in the queue?
    func checkQueueStatus() -> QueueStatus {
        if self.messageQueue.count <= 0 &&
            self.miscQueue.count <= 0 &&
            self.readQueue.count <= 0 {
            NotificationCenter.default.post(name: .queueIsEmpty, object: nil)

            // Use when the app is in the background
            // To end the background task
            self.exceedNotify?()
            self.exceedNotify = nil
            return .idle
        }
        return .running
    }

    /// Check the execute time limitation
    private func allowedToDequeue() -> Bool {
        guard let remainingTime = self.backgroundTimeRemaining?() else {
            // App in the foreground
            return true
        }

        // App in the background
        let isAllowed = remainingTime > 5.0
        if !isAllowed {
            if !self.isMiscRunning && !self.isMessageRunning {
                self.exceedNotify?()
                self.exceedNotify = nil
            }
        }
        return isAllowed
    }

    private func nextTask(from queue: PMPersistentQueueProtocol) -> Task? {
        // TODO: check dependency id, to skip or continue
        guard let next = queue.next() else {
            return nil
        }

        if let task = next.object as? Task {
            return task
        }

        return nil
    }

    private func dequeueIfNeeded() {
        guard internetStatusProvider.status.isConnected,
              self.checkQueueStatus() == .running,
              self.allowedToDequeue() else {return}
        if !self.hasDequeued {
            self.fetchMessageDataIfNeeded()
        }
        self.dequeueMessageQueue()
        self.dequeueMiscQueue()
    }

    private func dequeueMessageQueue() {
        guard !isMessageRunning && allowedToDequeue() else { return }

        guard let task = self.nextTask(from: self.messageQueue) else {
            if self.miscQueue.count == 0 {
                self.dequeueReadQueue()
            }
            return
        }

        let allTask = messageQueue.queueArray().tasks
        SystemLogger.log(
            message: "Tasks in msg queue: \(allTask.map(\.action))",
            category: .queue
        )

        guard task.dependencyIDs.count == 0 else {
            self.removeAllTasks(of: task.messageID, removalCondition: { action in
                switch action {
                case .saveDraft, .uploadAtt,
                     .uploadPubkey, .deleteAtt, .send:
                    return true
                default:
                    return false
                }
            }) {
                self.dequeueReadQueue()
            }
            return
        }

        guard let handler = self.handlers[task.userID] else {
            SystemLogger.log(
                message: "Removing due to no handler in msg queue: \(task.action)",
                category: .queue
            )
            _ = self.messageQueue.remove(task.uuid)
            self.dequeueMessageQueue()
            return
        }

        SystemLogger.log(
            message: "Dequeued task in msg queue: \(task.action)",
            category: .queue
        )

        let action = task.action
        if action == .signout,
           let _ = self.getMiscTasks(of: task.userID)
            .first(where: { $0.action == task.action }) {
            // The misc queue has running task
            // skip this task, let misc queue to handle signout task
            _ = self.messageQueue.remove(task.uuid)
            self.dequeueMessageQueue()
            return
        }

        self.isMessageRunning = true
        self.queue.async {
            // call handler to tell queue to continue
            handler.handleTask(task) { (task, result) in
                self.queue.async {
                    self.isMessageRunning = false
                    self.handle(result, of: task, on: self.messageQueue) { (isOnline) in
                        if isOnline {
                            self.dequeueMessageQueue()
                        }
                    }
                }
            }
        }
    }

    private func dequeueMiscQueue() {
        guard !self.isMiscRunning && self.allowedToDequeue() else {return}

        guard let task = self.nextTask(from: self.miscQueue) else {
            if self.messageQueue.count == 0 {
                self.dequeueReadQueue()
            }
            return
        }

        let allTask = miscQueue.queueArray().tasks
        SystemLogger.log(
            message: "Tasks in misc queue: \(allTask.map(\.action))",
            category: .queue
        )

        guard let handler = self.handlers[task.userID] else {
            SystemLogger.log(
                message: "Removing due to no handler in misc queue: \(task.action)",
                category: .queue
            )
            _ = self.miscQueue.remove(task.uuid)
            dequeueMiscQueue()
            return
        }
        let action = task.action

        SystemLogger.log(
            message: "Dequeued task in misc queue: \(task.action)",
            category: .queue
        )

        if action == .signout,
           let _ = self.getMessageTasks(of: task.userID)
            .first(where: { $0.action == task.action }) {
            // The message queue has running task
            // skip this task, let message queue to handle signout task
            _ = self.miscQueue.remove(task.uuid)
            self.dequeueMessageQueue()
            return
        }

        self.isMiscRunning = true
        self.queue.async {
            // call handler to tell queue to continue
            handler.handleTask(task) { (task, result) in
                self.queue.async {
                    self.isMiscRunning = false
                    self.handle(result, of: task, on: self.miscQueue) { (isOnline) in
                        if isOnline {
                            self.dequeueMiscQueue()
                        }
                    }
                }
            }
        }
    }

    /// - Returns: isOnline
    private func handle(_ result: TaskResult, of task: Task, on queue: PMPersistentQueueProtocol, completeHander: @escaping ((Bool) -> Void)) {

        if task.action == MessageAction.signout,
           let handler = self.handlers[task.userID] {
            _ = self.handlers.removeValue(forKey: handler.userID)
        }

        switch result.action {
        case .checkReadQueue:
            let removed = queue.queueArray().tasks
                .filter { $0.dependencyIDs.contains(task.uuid) }
            SystemLogger.log(
                message: "\(task.action) done, result: checkReadQueue, removing: \(removed.map(\.action))",
                category: .queue
            )
            removed.forEach { _ = queue.remove($0.uuid) }
            self.remove(task: task, on: queue)
            self.dequeueReadQueue()
            completeHander(true)
        case .none:
            self.remove(task: task, on: queue)
            completeHander(true)
        case .connectionIssue:
            // Forgot the signout task in offline mode
            switch task.action {
            case .signout, .uploadAtt:
                self.remove(task: task, on: queue)
            default:
                break
            }
            SystemLogger.log(message: "\(task.action) done, result: connection issue", category: .queue)
            completeHander(false)
        case .removeRelated:
            let removed = queue.queueArray().tasks
                .filter { $0.dependencyIDs.contains(task.uuid) }
            SystemLogger.log(
                message: "\(task.action) done, result: remove related, removing: \(removed.map(\.action))", 
                category: .queue
            )
            removed.forEach { _ = queue.remove($0.uuid) }
            self.remove(task: task, on: queue)
            completeHander(true)
        case .retry:
            completeHander(true)
            break
        }
    }

    private func remove(task: Task, on queue: PMPersistentQueueProtocol) {
        // Remove the dependency of the following tasks
        queue.queueArray().tasks
            .filter { $0.messageID == task.messageID }
            .forEach { pendingTask in
                if let idx = pendingTask.dependencyIDs.firstIndex(of: task.uuid) {
                    pendingTask.dependencyIDs.remove(at: idx)
                    queue.update(uuid: pendingTask.uuid, object: pendingTask)
                }
            }
        SystemLogger.log(
            message: "Removing: \(task.action)",
            category: .queue
        )
        // Remove the task
        _ = queue.remove(task.uuid)
    }

    private func dequeueReadQueue() {
        guard self.allowedToDequeue(),
              !self.readQueue.isEmpty else {
            _ = self.checkQueueStatus()
            return
        }
        let clourse = self.readQueue.remove(at: 0)
        // Execute the first closure in readQueue
        self.queue.async {
            clourse()
        }

        self.dequeueIfNeeded()
    }

    private func fetchMessageDataIfNeeded() {
        defer { self.hasDequeued = true }
        guard let task = self.nextTask(from: self.messageQueue) else {
            return
        }

        switch task.action {
        case .uploadAtt, .uploadPubkey:
            break
        default:
            return
        }

        // To prevent duplicate attachments upload
        // If the first task is to upload the attachment
        // insert a fetch action to the head of the message queue
        // Only the first task may duplicate, so only care about the first one

        let fetchTask = QueueManager.Task(messageID: task.messageID, action: .fetchMessageDetail, userID: task.userID, dependencyIDs: [], isConversation: false)
        _ = self.messageQueue.insert(uuid: fetchTask.uuid, object: fetchTask, index: 0)
    }
}

extension QueueManager {
    enum TaskAction {
        case none
        /// Queue is not block and readqueue > 0
        case checkReadQueue
        /// Stop dequeu
        case connectionIssue
        /// The task failed, remove related tasks
        case removeRelated
        /// Retry task
        case retry
    }

    struct TaskResult {
        var action: TaskAction
        /// The update won't be written into disk
        var retry: Int = 0

        init(action: TaskAction = .none) {
            self.action = action
        }
    }

    @objc(_TtCC5Share12QueueManager4Task) final class Task: NSObject, NSCoding {
        let uuid: TaskID
        let messageID: String
        let action: MessageAction
        let userID: UserID
        /// The taskID in this array should be done to execute this task
        var dependencyIDs: [TaskID]
        let isConversation: Bool

        init(uuid: TaskID = UUID(),
             messageID: String,
             action: MessageAction,
             userID: UserID,
             dependencyIDs: [TaskID],
             isConversation: Bool) {
            self.uuid = uuid
            self.messageID = messageID
            self.action = action
            self.userID = userID
            self.dependencyIDs = dependencyIDs
            self.isConversation = isConversation
        }

        func encode(with coder: NSCoder) {
            coder.encode(uuid, forKey: "uuid")
            coder.encode(messageID, forKey: "messageID")
            coder.encode(userID.rawValue, forKey: "userID")
            coder.encode(try? JSONEncoder().encode(action), forKey: "action")
            coder.encode(dependencyIDs, forKey: "dependencyIDs")
            coder.encode(isConversation, forKey: "isConversation")
        }

        required convenience init?(coder: NSCoder) {
            guard let uuid = coder.decodeObject(forKey: "uuid") as? UUID,
                  let messageID = coder.decodeObject(forKey: "messageID") as? String,
                  let userID = coder.decodeObject(forKey: "userID") as? String,
                  let dependencyIDs = coder.decodeObject(forKey: "dependencyIDs") as? [UUID],
                  let actionData = coder.decodeObject(forKey: "action") as? Data,
                  let action = try? JSONDecoder().decode(MessageAction.self, from: actionData),
                  coder.containsValue(forKey: "isConversation")
            else { return nil }

            let isConversation = coder.decodeBool(forKey: "isConversation")

            self.init(uuid: uuid,
                      messageID: messageID,
                      action: action,
                      userID: UserID(rawValue: userID),
                      dependencyIDs: dependencyIDs,
                      isConversation: isConversation)
        }
    }
}

// MARK: - ConnectionStatusReceiver
extension QueueManager: ConnectionStatusReceiver {
    func connectionStatusHasChanged(newStatus: ConnectionStatus) {
        connectionStatus = newStatus
    }
}

private extension Collection where Element == Any {

    var tasks: [QueueManager.Task] {
        compactMap { $0 as? [String: Any] }
        .compactMap { $0["object"] as? QueueManager.Task }
    }

}

// sourcery: mock
protocol QueueManagerProtocol {
    func addTask(_ task: QueueManager.Task, autoExecute: Bool, completion: ((Bool) -> Void)?)
    func addBlock(_ block: @escaping () -> Void)
    func queue(_ readBlock: @escaping () -> Void)
}

extension QueueManager: QueueManagerProtocol {
    func addBlock(_ block: @escaping () -> Void) {
        self.queue(block)
    }
}

#if !APP_EXTENSION
extension QueueManager: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
#endif
