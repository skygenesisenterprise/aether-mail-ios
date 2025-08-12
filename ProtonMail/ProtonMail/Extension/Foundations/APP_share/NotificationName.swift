//
//  NotificationDefined.swift
//  Proton Mail - Created on 8/11/15.
//
//
//  Copyright (c) 2019 Proton AG
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

extension Notification.Name {

    /// notify menu controller to switch views
    static var switchView: Notification.Name {
        return .init(rawValue: "MenuController.SwitchView")
    }

    static var scheduledMessageSucceed: Notification.Name {
        return .init(rawValue: "ScheduledMessageSucceed")
    }

    /// when received a custom url schema. ex. verify code
    static var customUrlSchema: Notification.Name {
        return .init(rawValue: "Application.CustomUrlSchema")
    }

    /// indicates the last remaining account has signed out
    static var didSignOutLastAccount: Notification.Name {
        return .init(rawValue: "UserDataServiceDidSignOutLastAccountNotification")
    }

    /// indicates an account has successfully signed in
    static var didSignIn: Notification.Name {
        return .init(rawValue: "UserDataServiceDidSignInNotification")
    }

    /// notify did unlock
    static var didUnlock: Notification.Name {
        return .init(rawValue: "UserDataServiceDidUnlockNotification")
    }

    /// notify token revoke
    static var didRevoke: Notification.Name {
        return .init("ApiTokenRevoked")
    }

    /// notify when primary account is revoked
    static var didPrimaryAccountLogout: Notification.Name {
        return .init("didPrimaryAccountLogout")
    }

    /// notify when the queue in the QueueManager is Empty
    static var queueIsEmpty: Notification.Name {
        return .init("queueIsEmpty")
    }

    static var attachmentUploaded: Notification.Name {
        return .init("attachmentUploaded")
    }

    static var attachmentUploadFailed: Notification.Name {
        return .init("attachmentUploadFailed")
    }

    static var showScheduleSendUnavailable: Notification.Name {
        return .init("showScheduleSendUnavailable")
    }

    static var shouldUpdateUserInterfaceStyle: Notification.Name {
        return .init("shouldUpdateUserInterfaceStyle")
    }

    static var tempNetworkError: Notification.Name {
        return .init("tempNetworkError")
    }

    static var pagesSwipeExpectation: Notification.Name {
       return .init(rawValue: "pagesSwipeExpectation")
    }

    static var appLockProtectionEnabled: Notification.Name {
        return .init("appLockProtectionEnabled")
    }

    static var appLockProtectionDisabled: Notification.Name {
        return .init("appLockProtectionDisabled")
    }

    static var appKeyEnabled: Notification.Name {
        return .init("appKeyEnabled")
    }

    static var appKeyDisabled: Notification.Name {
        return .init("appKeyDisabled")
    }

    static var sendMessageTaskSuccess: Notification.Name {
        return .init("sendMessageTaskSuccess")
    }

    static var sendMessageTaskFail: Notification.Name {
        return .init("sendMessageTaskFail")
    }

    static var messageSendFailAddressValidationIncorrect: Notification.Name {
        return .init("messageSendFailAddressValidationIncorrect")
    }

    static var addressesStatusAreChanged: Notification.Name {
        return .init("addressesStatusAreChanged")
    }

    static var cancelImportContactsTask: Notification.Name {
        return .init("cancelImportContactsTask")
    }
}

extension Notification {

    enum UserInfoKey: String {
        case errorMessage
    }
}
