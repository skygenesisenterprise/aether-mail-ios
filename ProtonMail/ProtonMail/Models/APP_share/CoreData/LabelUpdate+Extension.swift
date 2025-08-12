//
//  Contact.swift
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

extension LabelUpdate {
    struct Attributes {
        static let entityName = "LabelUpdate"
        static let userID = "userID"
        static let labelID = "labelID"
    }

    class func fetchLastUpdates(by labelIDs: [String], userID: String, context: NSManagedObjectContext) -> [LabelUpdate] {
        let fetchRequest = NSFetchRequest<LabelUpdate>(entityName: LabelUpdate.Attributes.entityName)
        let predicate = NSPredicate(format: "%K == %@ AND %K IN %@", LabelUpdate.Attributes.userID, userID, LabelUpdate.Attributes.labelID, labelIDs)
        fetchRequest.predicate = predicate

        do {
            return try context.fetch(fetchRequest)
        } catch {
        }
        return []
    }

    class func lastUpdate(by labelID: String, userID: String, inManagedObjectContext context: NSManagedObjectContext) -> LabelUpdate? {
        return context.managedObjectWithEntityName(Attributes.entityName, matching: [Attributes.labelID: labelID, Attributes.userID: userID]) as? LabelUpdate
    }

    class func lastUpdates(userID: String, inManagedObjectContext context: NSManagedObjectContext) -> [LabelUpdate] {
        return context.managedObjectsWithEntityName(Attributes.entityName,
                                                    matching: [Attributes.userID: userID]) as? [LabelUpdate] ?? []
    }

    class func newLabelUpdate(by labelID: String, userID: String, inManagedObjectContext context: NSManagedObjectContext) -> LabelUpdate {
        let update = LabelUpdate(context: context)

        update.start = Date.distantPast
        update.end = Date.distantPast
        update.update = Date.distantPast

        update.labelID = labelID
        update.userID = userID

        update.total = 0
        update.unread = 0

        return update
    }

    class func remove(by userID: String, inManagedObjectContext context: NSManagedObjectContext) -> Bool {
        if let toDeletes = context.managedObjectsWithEntityName(Attributes.entityName,
                                                                matching: [Attributes.userID: userID]) as? [LabelUpdate] {
            for update in toDeletes {
                context.delete(update)
            }
            if context.saveUpstreamIfNeeded() == nil {
                return true
            }
        }
        return false
    }
}
