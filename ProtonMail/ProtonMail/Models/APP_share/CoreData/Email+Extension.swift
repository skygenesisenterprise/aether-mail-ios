//
//  Email+Extension.swift
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

extension Email {
    struct Attributes {
        static let entityName = "Email"
        static let contactID = "contactID"
        static let email = "email"
        static let emailID = "emailID"
        static let userID = "userID"
        static let name = "name"
        static let lastUsedTime = "lastUsedTime"
    }

    class func emailForID(_ emailID: String, inManagedObjectContext context: NSManagedObjectContext) -> Email? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.emailID, matchingValue: emailID) as? Email
    }

    class func emailFor(emailID: String, userID: UserID, in context: NSManagedObjectContext) -> Email? {
        return context.managedObjectWithEntityName(
            Attributes.entityName,
            matching: [
                Attributes.emailID: emailID,
                Attributes.userID: userID.rawValue
            ]
        )
    }

    class func EmailForAddressWithContact(_ address: String,
                                          contactID: String,
                                          inManagedObjectContext context: NSManagedObjectContext) -> Email? {
        if let tempResults = context.managedObjectsWithEntityName(Attributes.entityName,
                                                                  forKey: Attributes.email,
                                                                  matchingValue: address) as? [Email] {
            for result in tempResults {
                if result.contactID == contactID {
                    return result
                }
            }
        }
        return nil
    }
}
