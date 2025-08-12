//
//  NSLayoutConstraint+Extension.swift
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

extension Array where Element == NSLayoutConstraint {

    @discardableResult
    func activate() -> [NSLayoutConstraint] {
        forEach { constraint in
            if let view = constraint.firstItem as? UIView,
               view.translatesAutoresizingMaskIntoConstraints {
                view.translatesAutoresizingMaskIntoConstraints = false
            }
            constraint.isActive = true
        }
        return self
    }

}

extension NSLayoutConstraint {
    func setPriority(as priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

extension UILayoutPriority {
    /// This priority can be used when you need .required but also need to handle compression to 0 height (common with table view cells).
    static let oneLessThanRequired = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - 1)
}
