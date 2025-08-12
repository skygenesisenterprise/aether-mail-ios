//
//  MessageObserver.swift
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
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

import CoreData

class MessageObserver: NSObject, NSFetchedResultsControllerDelegate {

    private let singleMessageFetchedController: NSFetchedResultsController<Message>
    private var messageHasChanged: ((Message) -> Void)?

    init(messageID: MessageID, contextProvider: CoreDataContextProviderProtocol) {
        let predicate = NSPredicate(format: "%K == %@", Message.Attributes.messageID, messageID.rawValue)
        let sortDescriptors = [
            NSSortDescriptor(
                key: Message.Attributes.time,
                ascending: false
            ),
            NSSortDescriptor(
                key: #keyPath(Message.order),
                ascending: false
            )
        ]
        singleMessageFetchedController = contextProvider.createFetchedResultsController(
            entityName: Message.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            fetchBatchSize: 0,
            sectionNameKeyPath: nil
        )
    }

    func observe(messageHasChanged: @escaping (Message) -> Void) {
        self.messageHasChanged = messageHasChanged
        singleMessageFetchedController.delegate = self
        try? singleMessageFetchedController.performFetch()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let message = singleMessageFetchedController.fetchedObjects?.first else { return }
        messageHasChanged?(message)
    }

}
