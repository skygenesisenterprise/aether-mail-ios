//
//  LabelFolderRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 13.11.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion

fileprivate struct id {
    static let labelNavBarButtonIdentifier = "UINavigationItem.topLabelButton"
    static let folderNavBarButtonIdentifier = "UINavigationItem.topFolderButton"
    static let trashNavBarButtonIdentifier = "UINavigationItem.topTrashButton"
    static let moreNavBarButtonIdentifier = "UINavigationItem.topMoreButton"
}

/*
 LabelFolderRobot class implements MailboxRobotInterface, contains actions and verifications for Labels or Folders mailbox functionality.
 */
class LabelFolderRobot : MailboxRobotInterface {

    var verify = Verify()
    
    /**
     * Contains all the validations that can be performed by [LabelFolderRobot].
     */
    class Verify: MailboxRobotVerifyInterface {}
}
