//
//  Email.swift
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

import Foundation
import CoreData

// sourcery: CoreDataHelpers
class Email: NSManagedObject {
    @NSManaged var userID: String
    @NSManaged var contactID: String
    @NSManaged var emailID: String
    @NSManaged var email: String
    @NSManaged var name: String  // this may need remove
    @NSManaged var defaults: NSNumber

    // @NSManaged var encrypt: NSNumber
    @NSManaged var order: NSNumber
    @NSManaged var type: String

    @NSManaged var contact: Contact
    @NSManaged var labels: NSSet

    @NSManaged var lastUsedTime: Date?
}
