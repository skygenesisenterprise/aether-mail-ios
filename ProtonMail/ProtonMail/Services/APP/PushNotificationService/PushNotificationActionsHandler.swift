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

import UserNotifications

final class PushNotificationActionsHandler {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        let notificationsToObserve: [Notification.Name] = [
            .appLockProtectionEnabled,
            .appLockProtectionDisabled,
            .appKeyEnabled,
            .appKeyDisabled,
            .didSignIn,
            .didSignOutLastAccount
        ]
        notificationsToObserve.forEach {
            dependencies.notificationCenter.addObserver(
                self,
                selector: #selector(updateRegisteredActions),
                name: $0,
                object: nil
            )
        }
    }

    /// Registers the relevant UNNotificationActions to be shown in push notifications if any
    func registerActions() {
        guard dependencies.isNotificationActionsFeatureEnabled else {
            // we remove actions in case they were registered in a previous test build
            removePushNotificationActions()
            return
        }
        if dependencies.lockCacheStatus.isAppLockedAndAppKeyEnabled {
            /// We don't show notification actions if extra security is enabled (FaceId, TouchId, PIN code, ... ).
            /// The reason for that is that the user's access token for API requests is encrypted and not accessible
            /// without user interaction. Therefore, it has been decided to not show notification actions because we
            /// can't fulfil them.
            removePushNotificationActions()
        } else {
            addPushNotificationActions()
        }
    }

    func isKnown(action actionIdentifier: String) -> Bool {
        PushNotificationAction(rawValue: actionIdentifier) != nil
    }

    func handle(action actionIdentifier: String, userId: UserID, messageId: String, completion: @escaping () -> Void) {
        guard let action = PushNotificationAction(rawValue: actionIdentifier) else {
            let message = "Unrecognised action \(actionIdentifier)"
            SystemLogger.log(message: message, category: .pushNotification, isError: true)
            completion()
            return
        }
        guard dependencies.isNetworkAvailable() else {
            SystemLogger.log(message: "Network unavailable", category: .pushNotification)
            enqueueTask(action: action, userId: userId, messageId: messageId)
            completion()
            return
        }
        executeTask(action: action, userId: userId, messageId: messageId, completion: completion)
    }
}

private extension PushNotificationActionsHandler {

    @objc
    private func updateRegisteredActions() {
        registerActions()
    }

    private func addPushNotificationActions() {
        let incomingEmail = UNNotificationCategory(
            identifier: Category.newIncomingMessage.rawValue,
            actions: Category.newIncomingMessage
                .actions
                .map { UNNotificationAction(identifier: $0.rawValue, title: $0.title, options: []) },
            intentIdentifiers: []
        )
        dependencies.userNotificationCenter.setNotificationCategories([incomingEmail])
    }

    private func removePushNotificationActions() {
        dependencies.userNotificationCenter.setNotificationCategories([])
    }

    private func enqueueTask(action: PushNotificationAction, userId: UserID, messageId: String) {
        let task = QueueManager.Task(
            messageID: "",
            action: .notificationAction(messageID: messageId, action: action),
            userID: userId,
            dependencyIDs: [],
            isConversation: false
        )
        dependencies.queue.addTask(task, autoExecute: true, completion: nil)
        SystemLogger.log(message: "Action enqueued \(action)", category: .pushNotification)
    }

    private func executeTask(
        action: PushNotificationAction,
        userId: UserID,
        messageId: String,
        completion: @escaping () -> Void
    ) {
        guard let userManager = dependencies.usersManager.getUser(by: userId) else {
            SystemLogger.log(message: "User not found for \(action)", category: .pushNotification, isError: true)
            completion()
            return
        }
        let params = ExecuteNotificationAction.Parameters(
            apiService: userManager.apiService,
            action: action,
            messageId: messageId
        )
        SystemLogger.log(message: "Request sent for action \(action)", category: .pushNotification)
        dependencies.actionRequest.callbackOn(.main).execute(params: params) { [weak self] result in
            switch result {
            case .success:
                completion()
            case .failure(let error):
                let message = "\(action) error: \(error)"
                SystemLogger.log(message: message, category: .pushNotification, isError: true)
                self?.enqueueTask(action: action, userId: userId, messageId: messageId)
                completion()
            }
        }
    }
}

extension PushNotificationActionsHandler {

    // A category returns a group of actions that should be shown together.
    enum Category: String {
        case newIncomingMessage = "message_created"

        var actions: [PushNotificationAction] {
            switch self {
            case .newIncomingMessage:
                return [.markAsRead, .archive, .moveToTrash]
            }
        }
    }
}

extension PushNotificationActionsHandler {
    struct Dependencies {
        let queue: QueueManagerProtocol
        let actionRequest: ExecuteNotificationActionUseCase
        let isNetworkAvailable: (() -> Bool)
        let lockCacheStatus: LockCacheStatus
        let notificationCenter: NotificationCenter
        let userNotificationCenter: UNUserNotificationCenter
        let usersManager: UsersManagerProtocol
        let isNotificationActionsFeatureEnabled: Bool

        init(
            queue: QueueManagerProtocol,
            actionRequest: ExecuteNotificationActionUseCase = ExecuteNotificationAction(),
            isNetworkAvailable: @escaping (() -> Bool) = {
                let provider = InternetConnectionStatusProvider.shared
                return provider.status.isConnected
            },
            lockCacheStatus: LockCacheStatus,
            notificationCenter: NotificationCenter = NotificationCenter.default,
            userNotificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current(),
            usersManager: UsersManagerProtocol,
            isNotificationActionsFeatureEnabled: Bool = true
        ) {
            self.queue = queue
            self.actionRequest = actionRequest
            self.isNetworkAvailable = isNetworkAvailable
            self.lockCacheStatus = lockCacheStatus
            self.notificationCenter = notificationCenter
            self.userNotificationCenter = userNotificationCenter
            self.usersManager = usersManager
            self.isNotificationActionsFeatureEnabled = isNotificationActionsFeatureEnabled
        }
    }
}
