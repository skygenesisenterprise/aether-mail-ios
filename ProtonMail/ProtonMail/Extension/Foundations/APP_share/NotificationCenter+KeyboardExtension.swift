//
//  NSNotificationCenter+KeyboardExtension.swift
//  Proton Mail
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

import UIKit

@objc protocol NSNotificationCenterKeyboardObserverProtocol: NSObjectProtocol {
    @objc optional func keyboardWillHideNotification(_ notification: Notification)
    @objc optional func keyboardWillShowNotification(_ notification: Notification)
    @objc optional func keyboardDidShowNotification(_ notification: Notification)
}

extension NotificationCenter {
    func addKeyboardObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol) {
        addObserver(observer, ifRespondsToAction: .willHide)
        addObserver(observer, ifRespondsToAction: .willShow)
        addObserver(observer, ifRespondsToAction: .didShow)
    }

    func removeKeyboardObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol) {
        removeObserver(observer, ifRespondsToAction: .willHide)
        removeObserver(observer, ifRespondsToAction: .willShow)
        removeObserver(observer, ifRespondsToAction: .didShow)
    }

    // MARK: - Private methods

    fileprivate enum KeyboardAction {
        case willHide
        case willShow
        case didShow

        var notificationName: String {
            switch self {
            case .willHide:
                return UIResponder.keyboardWillHideNotification.rawValue
            case .willShow:
                return UIResponder.keyboardWillShowNotification.rawValue
            default:
                return UIResponder.keyboardDidShowNotification.rawValue
            }
        }

        var selector: Selector {
            switch self {
            case .willHide:
                return #selector(NSNotificationCenterKeyboardObserverProtocol.keyboardWillHideNotification(_:))
            case .willShow:
                return #selector(NSNotificationCenterKeyboardObserverProtocol.keyboardWillShowNotification(_:))
            default:
                return #selector(NSNotificationCenterKeyboardObserverProtocol.keyboardDidShowNotification(_:))
            }
        }
    }

    fileprivate func addObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol, ifRespondsToAction action: KeyboardAction) {
        if keyboardObserver(observer, respondsToAction: action) {
            addObserver(observer, selector: action.selector, name: NSNotification.Name(rawValue: action.notificationName), object: nil)
        }
    }

    fileprivate func keyboardObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol, respondsToAction action: KeyboardAction) -> Bool {
        return observer.responds(to: action.selector)
    }

    fileprivate func removeObserver(_ observer: NSNotificationCenterKeyboardObserverProtocol, ifRespondsToAction action: KeyboardAction) {
        if keyboardObserver(observer, respondsToAction: action) {
            removeObserver(observer, name: NSNotification.Name(rawValue: action.notificationName), object: nil)
        }
    }
}
