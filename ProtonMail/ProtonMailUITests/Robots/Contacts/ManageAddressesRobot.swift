//
//  ManageAddressesRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion

fileprivate struct id {
    static func contactCellIdentifier(_ email: String) -> String { return "ContactGroupEditViewCell.\(email)" }
    static let doneButtonText = LocalString._general_done_button
}

/**
 ManageAddressesRobot class contains actions and verifications for Adding a Contact to Group.
 */
class ManageAddressesRobot: CoreElements {

    func addContactToGroup(_ withEmail: String) -> AddContactGroupRobot {
        return clickContact(withEmail).back()
    }
    
    func clickContact(_ withEmail: String) -> ManageAddressesRobot {
        cell(id.contactCellIdentifier(withEmail)).firstMatch().tap()
        return self
    }

    private func back() -> AddContactGroupRobot {
        button(id.doneButtonText).tap()
        return AddContactGroupRobot()
    }
}
