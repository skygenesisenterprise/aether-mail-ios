//
//  ContactGroupVO.swift
//  Proton Mail - Created on 2018/9/26.
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
import ProtonCoreServices
import UIKit

// contact group sub-selection
struct DraftEmailData: Hashable {
    let name: String
    let email: String

    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}

class ContactGroupVO: NSObject, ContactPickerModelProtocol {

    var modelType: ContactPickerModelState {
        get {
            return .contactGroup
        }
    }

    var ID: String
    @objc var contactTitle: String
    var displayName: String?
    var displayEmail: String?
    var contactImage: UIImage?
    private(set) var hasPGPPined: Bool
    private(set) var pgpEmails: [String] = []
    private(set) var hasNonePM: Bool
    private(set) var nonePMEmails: [String] = []
    private(set) var allMemberValidate = true
    private let contextProvider: CoreDataContextProviderProtocol

    var color: String? {
        if let color = groupColor {
            return color
        }

        return contextProvider.read { context in
            if let label = Label.labelForLabelName(
                contactTitle,
                inManagedObjectContext: context
            ) {
                groupColor = label.color
                groupSize = label.emails.count
                return label.color
            } else {
                return ColorManager.defaultColor
            }
        }
    }

    @objc var contactSubtitle: String? {
        get {
            let count = self.contactCount
            return String(format: LocalString._contact_groups_member_count_description, count)
        }
    }

    /*
     contact group subselection

     The contact information we can get from draft are name, email address, and group name

     So if the (name, email address) pair doesn't match any record inthe  current group,
     we will treat it as a new pair
     */
    private var selectedMembers: MultiSet<DraftEmailData>

    func getSelectedEmailsWithDetail() -> [ComposeViewModel.EncodableRecipient] {
        selectedMembers.map { member in
            ComposeViewModel.EncodableRecipient(name: member.key.name, address: member.key.email, group: contactTitle)
        }
    }

    /**
     Get all email addresses
    */
    func getSelectedEmailAddresses() -> [String] {
        return self.selectedMembers.map {$0.key.email}
    }

    /**
     Get all DraftEmailData (the count will match)
    */
    func getSelectedEmailData() -> [DraftEmailData] {
        var result: [DraftEmailData] = []
        for member in selectedMembers {
            for _ in 0..<member.value {
                result.append(member.key)
            }
        }
        return result
    }

    /**
     Updates the selected members (completely overwrite)
    */
    func overwriteSelectedEmails(with newSelectedMembers: [DraftEmailData]) {
        selectedMembers.removeAll()
        for member in newSelectedMembers {
            selectedMembers.insert(member)
        }
    }

    /**
     Select all emails from the contact group
     Notice: this method will clear all previous selections
    */
    func selectAllEmailFromGroup() {
        selectedMembers.removeAll()

        _ = contextProvider.read { context in
            if let label = Label.labelGroup(byID: self.ID, inManagedObjectContext: context) {
                for email in label.emails.allObjects as! [Email] {
                    let member = DraftEmailData.init(name: email.name, email: email.email)
                    selectedMembers.insert(member)
                }
            }
        }
    }

    private var groupSize: Int?
    private var groupColor: String?

    var contactCount: Int {
        if let size = groupSize {
            return size
        }

        return contextProvider.read { context in
            if let label = Label.labelForLabelName(
                contactTitle,
                inManagedObjectContext: context
            ) {
                groupColor = label.color
                groupSize = label.emails.count
                return label.emails.count
            } else {
                return 0
            }
        }
    }

    /**
      Calculates the group size, selected member count, and group color
     Information for composer collection view cell
    */
    func getGroupInformation() -> (memberSelected: Int, totalMemberCount: Int, groupColor: String) {
        let errorResponse = (0, 0, ColorManager.defaultColor)

        let emailMultiSet = MultiSet<DraftEmailData>()
        var color = ""
        // (1) get all email in the contact group
        if let label = contextProvider.read(block: { context in
            if self.ID.isEmpty {
                if let label = Label.labelForLabelName(self.contactTitle, inManagedObjectContext: context) {
                    return LabelEntity(label: label)
                } else {
                    return nil
                }
            } else {
                if let label = Label.labelForLabelID(self.ID, inManagedObjectContext: context) {
                    return LabelEntity(label: label)
                } else {
                    return nil
                }
            }
        }) {
            let emails = label.emailRelations
            color = label.color
            for email in emails {
                let member = DraftEmailData(
                    name: email.name,
                    email: email.email
                )
                emailMultiSet.insert(member)
            }
        } else {
            return errorResponse
        }

        // (2) get all that is NOT in the contact group, but is selected
        // Because we might have identical name-email pairs, we can't simply use a set
        //
        // We use the frequency map of all name-email pairs, and we
        // 2a) add pairs that are not present in the emailMultiSet
        // or
        // 2b) update the frequency counter of the emailMultiSet only if tmpMultiSet has a larger value
        for member in self.selectedMembers {
            let count = emailMultiSet[member.key] ?? 0
            if member.value > count {
                for _ in 0..<(member.value - count) {
                    emailMultiSet.insert(member.key)
                }
            }
        }

        let memberSelected = self.selectedMembers.reduce(0, {x, y in
            return x + y.value
        })
        let totalMemberCount = emailMultiSet.reduce(0, {
            x, y in
            return x + y.value
        })

        return (memberSelected, totalMemberCount, color)
    }

    init(
        ID: String,
        name: String,
        groupSize: Int? = nil,
        color: String? = nil,
        contextProvider: CoreDataContextProviderProtocol
    ) {
        self.ID = ID
        self.contactTitle = name
        self.groupColor = color
        self.groupSize = groupSize

        self.displayName = nil
        self.displayEmail = nil
        self.contactImage = nil
        self.hasPGPPined = false
        self.hasNonePM = false
        self.selectedMembers = MultiSet<DraftEmailData>()
        self.contextProvider = contextProvider
    }

    func equals(_ other: ContactPickerModelProtocol) -> Bool {
        return self.isEqual(other)
    }

    func update(mail: String, iconStatus: EncryptionIconStatus) {
        if iconStatus.isPGPPinned {
            self.hasPGPPined = true
            self.pgpEmails.append(mail)
        }
        if iconStatus.isNonePM {
            self.hasNonePM = true
            self.nonePMEmails.append(mail)
        }
        if iconStatus.isInvalid {
            self.allMemberValidate = false
        }
    }
}

extension ContactGroupVO {
    func copy(with zone: NSZone? = nil) -> Any {
        let contactGroup = ContactGroupVO(ID: ID, name: contactTitle, groupSize: groupSize, color: groupColor, contextProvider: contextProvider)
        return contactGroup
    }
}
