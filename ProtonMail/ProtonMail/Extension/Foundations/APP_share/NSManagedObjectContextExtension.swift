//
//  NSManagedObjectContextExtension.swift
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

extension NSManagedObjectContext {
    func managedObjectWithEntityName<T: NSManagedObject>(_ entityName: String, matching values: [String: CVarArg]) -> T? {
        let objects: [T]? = managedObjectsWithEntityName(entityName, matching: values)
        return objects?.first
    }

    func managedObjectsWithEntityName<T: NSManagedObject>(_ entityName: String, matching values: [String: CVarArg]) -> [T]? {
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)

        var subPredication: [NSPredicate] = []
        for (key, value) in values {
            let predicate = NSPredicate(format: "%K == %@", key, value)
            subPredication.append(predicate)
        }
        let predicateCompound = NSCompoundPredicate.init(type: .and, subpredicates: subPredication)
        fetchRequest.predicate = predicateCompound

        do {
            let results = try fetch(fetchRequest)
            return results
        } catch {
        }
        return nil
    }

    func managedObjectWithEntityName<T: NSManagedObject>(_ entityName: String, forKey key: String, matchingValue value: CVarArg) -> T? {
        let objects: [T]? = managedObjectsWithEntityName(entityName, forKey: key, matchingValue: value)
        return objects?.first
    }

    func managedObjectsWithEntityName<T: NSManagedObject>(_ entityName: String, forKey key: String, matchingValue value: CVarArg) -> [T]? {
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", key, value)

        do {
            let results = try fetch(fetchRequest)
            return results
        } catch {
        }
        return nil
    }

    func saveUpstreamIfNeeded(
        caller: StaticString = #function,
        file: StaticString = #file,
        line: UInt = #line
    ) -> NSError? {
        var error: NSError?
        do {
            if hasChanges {
                if !insertedObjects.isEmpty {
                    try obtainPermanentIDs(for: Array(insertedObjects))
                }

                try ObjC.catchException {
                    do {
                        try self.save()
                    } catch let savingError as NSError {
                        error = savingError
                    }
                }
                if let parentContext = parent {
                    PMAssertionFailure(
                        "This should never be needed, rootSavingContext has no parent and mainContext is never saved."
                    )
                    parentContext.performAndWait { () -> Void in
                        error = parentContext.saveUpstreamIfNeeded()
                    }
                }
            }
        } catch let ex as NSError {
            error = ex
        }

        if let error = error {
            assertionFailure("\(error)")

            Analytics.shared.sendError(.coreDataSavingError(error: error, caller: caller, file: file, line: line))
        }

        return error
    }

    func find(with objectID: NSManagedObjectID) -> NSManagedObject? {
        var msgObject: NSManagedObject?
        do {
            msgObject = try self.existingObject(with: objectID)
        } catch {
            msgObject = nil
        }
//        if let obj = msgObject as? T {
//            return obj
//        }
        return msgObject
    }

    // reference: https://www.avanderlee.com/swift/nsbatchdeleterequest-core-data/

    /// Executes the given `NSBatchDeleteRequest` and directly merges the changes to bring the given managed object context up to date.
    ///
    /// - Parameter batchDeleteRequest: The `NSBatchDeleteRequest` to execute.
    /// - Throws: An error if anything went wrong executing the batch deletion.
    public func executeAndMergeChanges(using batchDeleteRequest: NSBatchDeleteRequest) throws {
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}
