//
//  UserInfo+Locked.swift
//  Proton Mail - Created on 28/10/2018.
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
import ProtonCoreDataModel
import ProtonCoreKeymaker

extension Locked where T == [UserInfo] {
    internal init(clearValue: T, with key: MainKey) throws {
        let data = NSKeyedArchiver.archivedData(withRootObject: clearValue)
        let locked = try Locked<Data>(clearValue: data, with: key)
        self.init(encryptedValue: locked.encryptedValue)
    }

    internal func unlock(with key: MainKey) throws -> T {
        let locked = Locked<Data>(encryptedValue: self.encryptedValue)
        let data = try locked.unlock(with: key)
        let parsedData = try self.parse(data: data)
        return parsedData
    }

    internal func parse(data: Data) throws -> T {
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ProtonMail.UserInfo")
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "Share.UserInfo")
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PushService.UserInfo")
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PMCommon.UserInfo")
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ProtonCore_DataModel.UserInfo")
        NSKeyedUnarchiver.setClass(ToolbarActions.classForKeyedUnarchiver(), 
                                   forClassName: "ProtonCore_DataModel.ToolbarActions")
        NSKeyedUnarchiver.setClass(ReferralProgram.classForKeyedUnarchiver(), 
                                   forClassName: "ProtonCore_DataModel.ReferralProgram")

        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ProtonMail.Address")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "Share.Address")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PushService.Address")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PMAuthentication.Address")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PMCommon.Address")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ProtonCore_DataModel.Address")

        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ProtonMail.Key")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "Share.Key")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PushService.Key")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PMAuthentication.Key")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PMCommon.Key")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ProtonCore_DataModel.Key")

        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "UserInfo")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "Address")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "Key")

        guard let value = NSKeyedUnarchiver.unarchiveObject(with: data) as? T else {
            throw LockedErrors.keyDoesNotMatch
        }
        return value
    }
}
