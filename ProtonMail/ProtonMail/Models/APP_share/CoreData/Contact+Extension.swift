//
//  Contact+Extension.swift
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

extension Contact {

    struct Attributes {
        static let entityName = "Contact"
        static let contactID = "contactID"
        static let name = "name"
        static let emails = "emails"
        static let userID = "userID"
        static let sectionName = "sectionName"
        static let isSoftDeleted = "isSoftDeleted"
        static let cardData = "cardData"
    }

    // MARK: - methods

    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: Attributes.entityName, in: context)!, insertInto: context)
    }

    override func awakeFromInsert() {
        super.awakeFromInsert()
        replaceNilStringAttributesWithEmptyString()
    }

    class func contactForContactID(_ contactID: String, inManagedObjectContext context: NSManagedObjectContext) -> Contact? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.contactID, matchingValue: contactID) as? Contact
    }

    class func contactFor(contactID: String, userID: UserID, in context: NSManagedObjectContext) -> Contact? {
        return context.managedObjectWithEntityName(
            Attributes.entityName,
            matching: [
                Attributes.contactID : contactID,
                Attributes.userID  : userID.rawValue
            ]
        )
    }

    // notes: if this function call `getEmails` app crashes because it seems override the accessor CoreData creates?
    //http://stackoverflow.com/questions/36878192/inverse-relationship-with-core-data-causes-crash-when-adding-object-to-nsset
    func getEmailsArray() -> [Email]? {
        let emails = self.emails.allObjects as? [Email]
        return emails?.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.order.compare(rhs.order) == .orderedAscending
        })
    }

    func fixName(force: Bool = false) -> Bool {
        if !self.isCorrected || force {
            let name = self.name
            if !name.isEmpty {
                self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                if let emails = self.getEmailsArray(), let email = emails.first {
                    self.name = email.email.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            self.isCorrected = true
            return true
        }
        return false
    }

    #if !APP_EXTENSION
    class func makeTempContact(context: NSManagedObjectContext, userID: String, name: String, cardDatas: [CardData], emails: [ContactEditEmail]) throws -> Contact {
        let contact = Contact(context: context)
        contact.userID = userID
        contact.contactID = UUID().uuidString
        contact.name = name
        contact.cardData = try cardDatas.toJSONString()
        contact.size = NSNumber(value: 0)
        contact.uuid = UUID().uuidString
        contact.createTime = Date()
        contact.isDownloaded = true
        contact.isCorrected = true
        contact.needsRebuild = false
        _ = emails.map { $0.makeTempEmail(context: context, contact: contact) }
        return contact
    }
    #endif
}
