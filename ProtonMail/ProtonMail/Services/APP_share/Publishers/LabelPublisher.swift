// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData

// sourcery: mock
protocol LabelPublisherProtocol: AnyObject {
    var delegate: LabelListenerProtocol? { get set }

    func fetchLabels(labelType: LabelFetchType)
}

protocol LabelListenerProtocol: AnyObject {
    func receivedLabels(labels: [LabelEntity])
}

final class LabelPublisher: NSObject, LabelPublisherProtocol {
    typealias Dependencies = HasCoreDataContextProviderProtocol

    private var fetchResultsController: NSFetchedResultsController<Label>?

    let dependencies: Dependencies
    let params: Parameters

    weak var delegate: LabelListenerProtocol?

    init(parameters: Parameters, dependencies: Dependencies) {
        self.params = parameters
        self.dependencies = dependencies
    }

    func fetchLabels(labelType: LabelFetchType) {
        if fetchResultsController == nil {
            setUpResultsController(labelType: labelType)
        }
        fetchAndPublishTheData()
    }

    func fetchLabel(_ labelID: LabelID) {
        setUpResultsController(labelID: labelID)
        fetchAndPublishTheData()
    }

    private func fetchAndPublishTheData() {
        fetchResultsController?.managedObjectContext.perform {
            do {
                try self.fetchResultsController?.performFetch()
                self.handleFetchResult(objects: self.fetchResultsController?.fetchedObjects)
            } catch {
                let message = "LabelPublisher error: \(String(describing: error))"
                SystemLogger.log(message: message, category: .coreData, isError: true)
            }
        }
    }

    // MARK: Private methods

    private func setUpResultsController(labelID: LabelID) {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == 0",
            Label.Attributes.labelID,
            labelID.rawValue,
            Label.Attributes.isSoftDeleted
        )
        let sortDescriptor = NSSortDescriptor(
            key: Label.Attributes.name,
            ascending: true,
            selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
        )
        fetchResultsController = dependencies.contextProvider.createFetchedResultsController(
            entityName: Label.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: [sortDescriptor],
            fetchBatchSize: 0,
            sectionNameKeyPath: nil
        )
        fetchResultsController?.delegate = self
    }

    private func setUpResultsController(labelType: LabelFetchType) {
        fetchResultsController = dependencies.contextProvider.createFetchedResultsController(
            entityName: Label.Attributes.entityName,
            predicate: fetchRequestPredicate(for: labelType),
            sortDescriptors: fetchRequestDescriptors(for: labelType),
            fetchBatchSize: 0,
            sectionNameKeyPath: nil
        )
        fetchResultsController?.delegate = self
    }

    private func fetchRequestPredicate(for type: LabelFetchType) -> NSPredicate {
        let folderPredicate = predicateForFolderType()
        switch type {
        case .all:
            return NSPredicate(
                format: "(labelID MATCHES %@) AND ((%K == 1) OR (%K == 3)) AND (%K == %@)",
                "(?!^\\d+$)^.+$",
                Label.Attributes.type,
                Label.Attributes.type,
                Label.Attributes.userID,
                params.userID.rawValue
            )

        case .folder:
            return folderPredicate

        case .folderWithInbox:
            let labels: [Message.Location] = [.inbox, .archive, .trash, .spam]
            let defaults = NSPredicate(format: "labelID IN %@", labels.map(\.rawValue))
            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folderPredicate])

        case .folderWithOutbox:
            let labels: [Message.Location] = [.sent, .archive, .trash]
            let defaults = NSPredicate(format: "labelID IN %@", labels.map(\.rawValue))
            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folderPredicate])

        case .label:
            return NSPredicate(
                format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == %@)",
                "(?!^\\d+$)^.+$",
                Label.Attributes.type,
                Label.Attributes.userID,
                params.userID.rawValue
            )

        case .contactGroup:
            return NSPredicate(
                format: "(%K == 2) AND (%K == %@) AND (%K == 0)",
                Label.Attributes.type,
                Label.Attributes.userID,
                params.userID.rawValue,
                Label.Attributes.isSoftDeleted
            )
        }
    }

    private func predicateForFolderType() -> NSPredicate {
        NSPredicate(
            format: "(labelID MATCHES %@) AND (%K == 3) AND (%K == %@)",
            "(?!^\\d+$)^.+$",
            Label.Attributes.type,
            Label.Attributes.userID,
            params.userID.rawValue
        )
    }

    private func fetchRequestDescriptors(for type: LabelFetchType) -> [NSSortDescriptor] {
        if type != .contactGroup {
            return [NSSortDescriptor(key: Label.Attributes.order, ascending: true)]
        } else {
            return [
                NSSortDescriptor(
                    key: Label.Attributes.name,
                    ascending: true,
                    selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                )
            ]
        }
    }

    private func handleFetchResult(objects: [NSFetchRequestResult]?) {
        let labels = (objects as? [Label]) ?? []
        let labelEntities = labels.compactMap(LabelEntity.init)
        delegate?.receivedLabels(labels: labelEntities)
    }
}

extension LabelPublisher: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        handleFetchResult(objects: controller.fetchedObjects)
    }
}

extension LabelPublisher {

    struct Parameters {
        let userID: UserID
    }
}
