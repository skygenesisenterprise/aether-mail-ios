//
//  DraftsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 08.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest
import fusion

fileprivate struct id {
    static let messageTitleLabelIdentifier = "mailboxMessageCell.titleLabel"
    static let mailboxMessageCellIdentifier = "NewMailboxMessageCell.mailboxMessageCell"
    static func messageCellIdentifier(_ subject: String) -> String { return subject.replacingOccurrences(of: " ", with: "_") }
}

/**
 * [DraftsRobot] implements [MailboxRobotInterface],
 * contains actions and verifications for Drafts composer functionality.
 */
class DraftsRobot: MailboxRobotInterface {
    static let noRecipientText = "No Recipient"

    var verify = Verify()
    
    override func searchBar() -> SearchRobot {
        return super.searchBar()
    }

    override func refreshMailbox() -> DraftsRobot {
        super.refreshMailbox()
        return self
    }

    func clickDraftBySubject(_ subject: String) -> ComposerRobot {
        super.clickMessageBySubject(subject)
        return ComposerRobot()
    }
    
    func clickDraftByIndex(_ index: Int) -> ComposerRobot {
        super.clickMessageByIndex(index)
        return ComposerRobot()
    }

    /**
     * Contains all the validations that can be performed by [Drafts].
     */
    class Verify: MailboxRobotVerifyInterface {

        func draftMessageSaved(_ draftSubject: String?) -> DraftsRobot {
            return DraftsRobot()
        }
        
        func messageWithSubjectExists(_ subject: String) {
            staticText(subject).waitUntilExists().checkExists()
        }
        
        func messageWithSubjectAndRecipientExists(_ subject: String, _ to: String) {
            staticText(subject)
                .firstMatch()
                .waitUntilExists()
                .checkExists()
        }

        func messageWithSubjectAndRecipientAndInitialsExists(subject: String, to: String, initials: String) {
            let messageCell = cell("NewMailboxMessageCell.\(subject)")
                .waitUntilExists()
                .checkExists()
            let isCorrect = messageCell.label()?.hasPrefix("\(initials), \(subject), \(to),") ?? false
            XCTAssertTrue(isCorrect)
        }
    }
}

