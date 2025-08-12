//
//  ContactGroupDataService.swift
//  Proton Mail - Created on 2018/8/20.
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
import Groot
import PromiseKit
import ProtonCoreServices

// sourcery: mock
protocol ContactGroupsProviderProtocol: AnyObject {
    func getAllContactGroupVOs() -> [ContactGroupVO]
}

class ContactGroupsDataService: ContactGroupsProviderProtocol {
    func cleanUp() {
            coreDataService.performAndWaitOnRootSavingContext { context in
                let groups = self.labelDataService.getAllLabels(of: .contactGroup, context: context)
                groups.forEach {
                    context.delete($0)
                }
            }
    }

    private let apiService: APIService
    private let labelDataService: LabelsDataService
    private let coreDataService: CoreDataContextProviderProtocol
    private weak var queueManager: QueueManager?
    private let userID: UserID

    init(api: APIService, labelDataService: LabelsDataService, coreDataService: CoreDataContextProviderProtocol, queueManager: QueueManager, userID: UserID) {
        self.apiService = api
        self.labelDataService = labelDataService
        self.coreDataService = coreDataService
        self.queueManager = queueManager
        self.userID = userID
    }

    /**
     Create a new contact group on the server and save it in core data
     
     - Parameters:
     - name: The name of the contact group
     - color: The color of the contact group
     - objectID: CoreData object ID of group label
     */
    func createContactGroup(name: String, color: String, objectID: String? = nil) -> Promise<String> {
        return Promise {
            seal in
            self.labelDataService.createNewLabel(name: name, color: color, type: .contactGroup, objectID: objectID) { (labelId, error) in
                if let err = error {
                    seal.reject(err)
                } else {
                    seal.fulfill(labelId ?? "")
                }
            }
        }
    }

    /**
     Edit a contact group on the server and edit it in core data
     
     - Parameters:
     - name: The name of the contact group
     - color: The color of the contact group
     */
    func editContactGroup(groupID: String, name: String, color: String) -> Promise<Void> {
        return Promise { seal in
            let route = UpdateLabelRequest(id: groupID, name: name, color: color)
            self.apiService.perform(request: route, response: CreateLabelRequestResponse()) { _, response in
                if let error = response.error {
                    seal.reject(error)
                } else {
                    if let updatedContactGroup = response.label {
                        self.labelDataService.addNewLabel(updatedContactGroup)
                        seal.fulfill(())
                    } else {
                        seal.reject(NSError.unableToParseResponse(response))
                    }
                }
            }
        }
    }

    /**
     Delete a contact group on the server and delete it in core data
     
     - Parameters:
     - name: The name of the contact group
     */
    func deleteContactGroup(groupID: String) -> Promise<Void> {
        return Promise { seal in
            let eventAPI = DeleteLabelRequest(lable_id: groupID)
            self.apiService.perform(request: eventAPI, response: DeleteLabelRequestResponse()) { _, response in
                if let error = response.error {
                    seal.reject(error)
                } else {
                    if response.returnedCode != nil {
                        // successfully deleted on the server
                        do {
                            try self.coreDataService.write { context in
                                let label = Label.labelForLabelID(groupID, inManagedObjectContext: context)
                                if let label = label {
                                    context.delete(label)
                                }
                                seal.fulfill(())
                            }
                        } catch {
                            seal.reject(error)
                        }
                    } else {
                        seal.reject(NSError.unableToParseResponse(response))
                    }
                }
            }
        }
    }

    func addEmailsToContactGroup(groupID: LabelID, emailList: [EmailEntity], emailIDs: [String]? = nil) -> Promise<Void> {
        return Promise { seal in
            var emailList = emailList
            // check
            if emailList.isEmpty && (emailIDs ?? []).isEmpty {
                seal.fulfill(())
                return
            }

            if let emailIDs = emailIDs {
                var mails: [EmailEntity] = []
                self.coreDataService.performAndWaitOnRootSavingContext { context in
                    mails = emailIDs
                        .compactMap { Email.emailForID($0, inManagedObjectContext: context)}.map(EmailEntity.init)
                }
                emailList += mails
            }

            let emails = emailList.map { $0.emailID }

            let route = ContactLabelAnArrayOfContactEmailsRequest(labelID: groupID, contactEmailIDs: emails)
            self.apiService.perform(request: route, response: ContactLabelAnArrayOfContactEmailsResponse()) { _, response in
                if let error = response.error {
                    seal.reject(error)
                } else {
                    if !response.emailIDs.isEmpty {
                        // save
                        self.coreDataService.performOnRootSavingContext { context in
                            let label = Label.labelForLabelID(groupID.rawValue, inManagedObjectContext: context)

                            let emailsToUse = emailList.compactMap { (email) -> Email? in
                                try? context.existingObject(with: email.objectID.rawValue) as? Email
                            }

                            if let label = label,
                                var newSet = label.emails as? Set<Email> {
                                // insert those email objects that is in the response only
                                for emailID in response.emailIDs {
                                    for email in emailsToUse {
                                        if email.emailID == emailID {
                                            newSet.insert(email)
                                            break
                                        }
                                    }
                                }

                                label.emails = newSet as NSSet

                                if let error = context.saveUpstreamIfNeeded() {
                                    seal.reject(error)
                                } else {
                                    seal.fulfill(())
                                }
                            } else {
                                seal.reject(ContactGroupEditError.InternalError)
                            }
                        }
                    } else {
                        seal.reject(NSError.unableToParseResponse(response))
                    }
                }
            }
        }
    }

    func removeEmailsFromContactGroup(groupID: LabelID, emailList: [EmailEntity], emailIDs: [String]? = nil) -> Promise<Void> {
        return Promise {
            seal in
            var emailList = emailList
            let emailIDs = emailIDs ?? []
            // check
            if emailList.isEmpty && emailIDs.isEmpty {
                seal.fulfill(())
                return
            }
            var mails: [EmailEntity] = []
            self.coreDataService.performAndWaitOnRootSavingContext { context in
                mails = emailIDs
                    .compactMap { Email.emailForID($0, inManagedObjectContext: context) }.map(EmailEntity.init)
            }
            emailList += mails

            let emails = emailList.map { $0.emailID }
            let route = ContactUnlabelAnArrayOfContactEmailsRequest(labelID: groupID, contactEmailIDs: emails)
            self.apiService.perform(request: route, response: ContactUnlabelAnArrayOfContactEmailsResponse()) { _, response in
                if let error = response.error {
                    seal.reject(error)
                } else {
                    if !response.emailIDs.isEmpty {
                        // save

                        self.coreDataService.enqueueOnRootSavingContext { context in
                            let label = Label.labelForLabelID(groupID.rawValue, inManagedObjectContext: context)

                            // remove only the email objects in the response
                            if let label = label {
                                let emailObjects = label.mutableSetValue(forKey: Label.Attributes.emails)

                                for emailID in response.emailIDs {
                                    for email in emailList {
                                        if email.emailID.rawValue == emailID {
                                            if let emailToDelete = emailObjects.compactMap({ $0 as? Email }).first(where: { email in
                                                return email.emailID == emailID
                                            }) {
                                                emailObjects.remove(emailToDelete)
                                            }
                                        }
                                    }
                                }

                                if let error = context.saveUpstreamIfNeeded() {
                                    seal.reject(error)
                                } else {
                                    seal.fulfill(())
                                }

                            } else {
                                seal.reject(ContactGroupEditError.InternalError)
                            }
                        }
                    } else {
                        seal.reject(NSError.unableToParseResponse(response))
                    }
                }
            }
        }
    }

    func getAllContactGroupVOs() -> [ContactGroupVO] {
        coreDataService.read { context in
            let labels = self.labelDataService.getAllLabels(of: .contactGroup, context: context)
            return labels.map { label in
                ContactGroupVO(ID: label.labelID, name: label.name, groupSize: label.emails.count, color: label.color, contextProvider: coreDataService)
            }
        }
    }
}

// MAKR: Queue
extension ContactGroupsDataService {
    func queueCreate(name: String, color: String, emailIDs: [String]) -> Promise<Void> {
        return Promise<String> { [weak self] seal in
            guard let self = self else { return }
            self.coreDataService.performAndWaitOnRootSavingContext { context in
                // Create a temporary label for display, the label will be removed after getting response
                let groupLabel = Label.makeGroupLabel(context: context,
                                                      userID: self.userID.rawValue,
                                                      color: color,
                                                      name: name,
                                                      emailIDs: emailIDs)
                if let error = context.saveUpstreamIfNeeded() {
                    seal.reject(error)
                } else {
                    let objectID = groupLabel.objectID.uriRepresentation().absoluteString
                    seal.fulfill(objectID)
                }
            }
        }.then { objectID -> Promise<Void> in
            let action: MessageAction = .addContactGroup(objectID: objectID, name: name, color: color, emailIDs: emailIDs)
            let task = QueueManager.Task(messageID: "", action: action, userID: self.userID, dependencyIDs: [], isConversation: false)
            _ = self.queueManager?.addTask(task)
            return Promise()
        }
    }

    func queueUpdate(groupID: String, name: String, color: String, addedEmailIDs: [String], removedEmailIDs: [String]) -> Promise<Void> {
        return Promise<String> { [weak self] seal in
            guard let self = self else { return }
            self.coreDataService.performOnRootSavingContext { context in
                guard let label = Label.labelGroup(byID: groupID, inManagedObjectContext: context) else {
                    seal.reject(NSError(domain: "No Label is found", code: 999))
                    return
                }
                label.name = name
                label.color = color
                if var mails = label.emails.allObjects as? [Email] {
                    for id in addedEmailIDs {
                        if let _ = mails.first(where: { $0.emailID == id }) { continue }
                        guard let mail = Email.emailForID(id, inManagedObjectContext: context) else { continue }
                        mails.append(mail)
                    }
                    for id in removedEmailIDs {
                        guard let index = mails.firstIndex(where: { $0.emailID == id }) else {
                            continue
                        }
                        mails.remove(at: index)
                    }
                    label.emails = Set(mails) as NSSet
                }

                if let error = context.saveUpstreamIfNeeded() {
                    seal.reject(error)
                } else {
                    let objectID: String = label.objectID.uriRepresentation().absoluteString
                    seal.fulfill(objectID)
                }
            }
        }.then { objectID -> Promise<Void> in
            let action: MessageAction = .updateContactGroup(objectID: objectID, name: name, color: color, addedEmailIDs: addedEmailIDs, removedEmailIDs: removedEmailIDs)
            let task = QueueManager.Task(messageID: "", action: action, userID: self.userID, dependencyIDs: [], isConversation: false)
            _ = self.queueManager?.addTask(task)
            return Promise()
        }
    }

    func queueDelete(groupID: String) -> Promise<Void> {
        let userID = self.userID
        let queue = self.queueManager
        return Promise<Void> { seal in
            self.coreDataService.performOnRootSavingContext { context in
                guard let label = Label.labelGroup(byID: groupID, inManagedObjectContext: context) else {
                    seal.fulfill_()
                    return
                }
                label.isSoftDeleted = true
                if let error = context.saveUpstreamIfNeeded() {
                    seal.reject(error)
                    return
                }
                let objectID = label.objectID.uriRepresentation().absoluteString
                let action: MessageAction = .deleteContactGroup(objectID: objectID)
                let task = QueueManager.Task(messageID: "", action: action, userID: userID, dependencyIDs: [], isConversation: false)
                queue?.addTask(task)
                seal.fulfill_()
            }
        }
    }
}
