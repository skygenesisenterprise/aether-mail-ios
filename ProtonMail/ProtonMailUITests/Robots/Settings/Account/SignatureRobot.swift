//
//  SignatureRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion

fileprivate struct id {
    static let enableSignatureStaticTextLabel = LocalString._settings_enable_signature_title
    static let enableMobileSignatureStaticTextLabel = LocalString._settings_enable_signature_title
    static let saveNavBarButtonIdentifier = LocalString._general_save_action
    static let backNavBarButtonIdentifier = "UINavigationItem.leftBarButtonItem"
    static let saveNavBarButtonLabel = LocalString._general_save_action
}

/**
 Class represents Signature and Mobile signature view.
 */
class SignatureRobot: CoreElements {
    
    func disableSignature() -> SignatureRobot {
        if (swittch().byIndex(0).value() as! String != "0") {
            /// Turn switch OFF and then ON
            swittch().byIndex(0).tap()
        } else {
            /// Turn switch ON and then OFF
            swittch().byIndex(0).tap()
            swittch().byIndex(0).tap()
        }
        return self
    }
    
    func enableSignature() -> SignatureRobot {
        if (swittch().byIndex(0).value() as! String != "0") {
            /// Turn switch OFF and then ON
            swittch().byIndex(0).tap()
            swittch().byIndex(0).tap()
        } else {
            /// Turn switch ON
            swittch().byIndex(0).tap()
        }
        return self
    }
    
    func save() -> AccountSettingsRobot {
        button(id.saveNavBarButtonIdentifier).tap()
        return AccountSettingsRobot()
    }

    func navigateBackToAccountSettings() -> AccountSettingsRobot {
        button(id.backNavBarButtonIdentifier).tap()
        return AccountSettingsRobot()
    }

    func setSignatureText(_ signature: String) -> SignatureRobot {
        textView().byIndex(0).multiTap(3).typeText(signature)
        return self
    }
    
    class Verify: CoreElements {
        
        func saveButtonIsDisabled() -> SignatureRobot {
            button(id.saveNavBarButtonIdentifier).checkDisabled()
            return SignatureRobot()
        }
    }
}
