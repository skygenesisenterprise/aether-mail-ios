//
//  UIAlertAction+Extension.swift
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

extension UIAlertAction {
    class func okAction(_ handler: ((UIAlertAction?) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: LocalString._general_ok_action,
                             style: .default,
                             handler: handler)
    }

    class func closeAction(_ handler: ((UIAlertAction?) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: LocalString._general_close_action,
                             style: .default,
                             handler: handler)
    }

    class func cancelAction(_ handler: ((UIAlertAction?) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: LocalString._general_cancel_action,
                             style: .default,
                             handler: handler)
    }
}
