//
//  LabelsAndFoldersRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion

fileprivate struct id {
    static let newFolderText = "New folder"
    static let newLabel = "New label"
    static let folderNameTextFieldIdentifier = "Label_Name.nameField"
    static let createButtonIdentifier = "LabelEditViewController.applyButton"
    static let closeButtonIdentifier = "LabelEditViewController.closeButton"
    static let keyboardDoneIdentifier = "Done"
    static let saveButtonLabel = LocalString._general_save_action
    static let deleteCellIdentifier = "LabelEditViewController.deleteCell"
    static let confirmDeleteButtonText = LocalString._general_delete_action
    static func labelFolderCellIdentifier(_ name: String) -> String { return "LabelTableViewCell.\(name)" }
    static func selectLabelFolderCellIdentifiert(_ name: String) -> String { return "MenuItemTableViewCell.\(name)" }
    static func editLabelFolderButtonIdentifier(_ name: String) -> String { return "MenuItemTableViewCell.\(name)" }
    static let colorCollectionViewCellIdentifier = "LabelPaletteCell.LabelColorCell"
}

/**
 LabelsAndFoldersRobot class represents Labels/Folders view.
 */
class AccountSettingsLabelsAndFoldersRobot: CoreElements {
    
    var verify = Verify()

    func addFolder() -> AccountSettingsAddFolderLabelRobot {
        staticText(id.newFolderText).tap()
        return AccountSettingsAddFolderLabelRobot()
    }
    
    func addLabel() -> AccountSettingsAddFolderLabelRobot {
        staticText(id.newLabel).tap()
        return AccountSettingsAddFolderLabelRobot()
    }
    
    func deleteFolderLabel(_ name: String) -> AccountSettingsLabelsAndFoldersRobot {
        return selectFolderLabel(name).delete().confirmDelete()
    }
    
    func editFolderLabel(_ folderName: String) -> AccountSettingsAddFolderLabelRobot {
        cell(id.selectLabelFolderCellIdentifiert(folderName)).tap()
        return AccountSettingsAddFolderLabelRobot()
    }
    
    func close() -> AccountSettingsRobot {
        button(id.closeButtonIdentifier).tap()
        return AccountSettingsRobot()
    }
    
    func selectFolderLabel(_ name: String) -> AccountSettingsAddFolderLabelRobot {
        cell(id.selectLabelFolderCellIdentifiert(name))
            .firstMatch()
            .swipeUpUntilVisible(maxAttempts: 20)
            .tap()
        return AccountSettingsAddFolderLabelRobot()
    }

    /**
     Contains all the validations that can be performed by LabelsAndFoldersRobot.
     */
    class Verify: CoreElements {
        
        func folderLabelExists(_ name: String) {
            cell(id.labelFolderCellIdentifier(name)).waitUntilExists().checkExists()
        }
        
        func folderLabelDeleted(_ name: String) {
            cell(id.labelFolderCellIdentifier(name)).waitUntilGone()
        }
    }
}
