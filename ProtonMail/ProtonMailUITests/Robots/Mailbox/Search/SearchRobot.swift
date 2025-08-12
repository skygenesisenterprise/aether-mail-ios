//
//  SearchRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 08.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest
import fusion

fileprivate struct id {
    static let searchBarIdentifier = "SearchViewController.customView.searchBar"
    static let searchKeyboardButtonText = LocalString._general_search_placeholder
    static let cancelButttonIdentifier = LocalString._general_cancel_button
    static func messageSenderLabelIdentifier(_ subject: String) -> String { return "\(subject).senderLabel" }
    static func draftCellIdentifier(_ subject: String) -> String { return "NewMailboxMessageCell.\(subject)" }
    static func messageCellIdentifier(_ subject: String) -> String { return "NewMailboxMessageCell.\(subject)" }
}

/**
 SearchRobot class contains actions and verifications for Search functionality.
 */
class SearchRobot: CoreElements {

    var verify: Verify! = Verify()
    
    func searchMessageText(_ subject: String) -> SearchRobot {
        return typeTextToSearch(subject)
            .tapKeyboardSearchButton()
    }
    
    func clickSearchedMessageBySubject(_ subject: String) -> MessageRobot {
        cell(id.messageCellIdentifier(subject)).firstMatch().tap()
        return MessageRobot()
    }
    
    func clickSearchedDraftBySubject(_ subject: String) -> ComposerRobot {
        cell(id.draftCellIdentifier(subject)).firstMatch().tap()
        return ComposerRobot()
    }

    func goBackToInbox() -> InboxRobot {
        button(id.cancelButttonIdentifier).tap()
        return InboxRobot()
    }
    
    func goBackToDrafts() -> DraftsRobot {
        button(id.cancelButttonIdentifier).tap()
        return DraftsRobot()
    }
    
    private func typeTextToSearch(_ text: String) -> SearchRobot {
        otherElement(id.searchBarIdentifier).onDescendant(textField().byIndex(0)).typeText(text)
        return self
    }
    
    private func tapKeyboardSearchButton() -> SearchRobot {
        button(id.searchKeyboardButtonText).tap()
        return self
    }
    
    class Verify: CoreElements {
        
        @discardableResult
        func messageExists(_ subject: String) -> SearchRobot {
            cell(id.messageCellIdentifier(subject)).firstMatch().checkExists()
            return SearchRobot()
        }
        
        @discardableResult
        func draftMessageExists(_ subject: String) -> SearchRobot {
            cell(id.draftCellIdentifier(subject.replaceSpaces())).firstMatch().checkExists()
            return SearchRobot()
        }
        
        @discardableResult
        func senderAddressExists(_ sender: String, _ title: String) -> SearchRobot {
            cell(id.messageCellIdentifier(title)).firstMatch()
                .onDescendant(staticText().hasLabel(sender)).waitUntilExists().checkExists()
            return SearchRobot()
        }
        
        func noResultsTextIsDisplayed() {
            staticText("No results found").waitUntilExists().checkExists()
        }
    }
}
