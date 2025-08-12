//
//  AccountSettingsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion

fileprivate struct id {
    static let singlePasswordLabel = L10n.AccountSettings.loginPassword
    static let recoveryEmailLabel = L10n.AccountSettings.recoveryEmail
    static let displayNameLabel = "Display Name"
    static let defaultLabel = LocalString._general_default
    static let signatureLabel = LocalString._settings_signature_title
    static let blockListLabel = "Block list"
    static let deleteAccount = "Delete account"
    static let mobileSignatureLabel = "Mobile Signature"
    static let defaultRightTextIdentifier = "Default.rightText"
    
    static let signatureRightStaticTextIdentifier = "Signature.rightText"
    static let mobileSignatureRightStaticTextIdentifier = "Mobile_Signature.rightText"
    static let onStaticTextLabel = LocalString._settings_On_title
    static let offStaticTextLabel = LocalString._settings_Off_title

    static let privacyLabel = LocalString._privacy
    static let labelsIdentifier = "SettingsGeneralCell.Labels"
    static let foldersIdentifier = "SettingsGeneralCell.Folders"
    static let signatureStaticTextLabel = LocalString._settings_signature_title
    static let signatureOnStaticTextLabel = LocalString._springboard_shortcuts_composer
    static let privacySignatureStaticTextLabel = LocalString._privacy
    static let backNavBarButtonIdentifier = LocalString._menu_settings_title
}

/**
 AccountSettingsRobot class contains actions and verifications for Account settings functionality.
 */
class AccountSettingsRobot: CoreElements {
    
    var verify = Verify()
    
    func labels() -> AccountSettingsLabelsAndFoldersRobot {
        cell(id.labelsIdentifier).tap()
        return AccountSettingsLabelsAndFoldersRobot()
    }
    
    func folders() -> AccountSettingsLabelsAndFoldersRobot {
        cell(id.foldersIdentifier).tap()
        return AccountSettingsLabelsAndFoldersRobot()
    }
    
    func defaultEmailAddress() -> DefaultEmailAddressRobot {
        staticText(id.defaultLabel).tap()
        return DefaultEmailAddressRobot()
    }
    
    func displayName() -> DisplayNameRobot {
        staticText(id.displayNameLabel).tap()
        return DisplayNameRobot()
    }
    
    func mobileSignature() -> SignatureRobot {
        staticText(id.mobileSignatureLabel).tap()
        return SignatureRobot()
    }
    
    func privacy() -> PrivacyRobot {
        staticText(id.privacySignatureStaticTextLabel).tap()
        return PrivacyRobot()
    }
    
    func recoveryEmail() -> RecoveryEmailRobot {
        staticText(id.recoveryEmailLabel).tap()
        return RecoveryEmailRobot()
    }
    
    func singlePassword() -> SinglePasswordRobot {
        staticText(id.singlePasswordLabel).tap()
        return SinglePasswordRobot()
    }

    func signature() -> SignatureRobot {
        staticText(id.signatureLabel).tap()
        return SignatureRobot()
    }

    func blockList() -> BlockListRobot {
        staticText(id.blockListLabel).swipeUpUntilVisible().tap()
        return BlockListRobot()
    }
    
    func deleteAccount<T: CoreElements>(to: T) -> T {
        staticText(id.deleteAccount).tap()
        return T()
    }
    
    func navigateBackToSettings() -> SettingsRobot {
        button(id.backNavBarButtonIdentifier).tap()
        return SettingsRobot()
    }
    
    /**
     DefaultEmailAddressRobot represents the modal where multiple emails are shown.
     */
    class DefaultEmailAddressRobot {
        
        var verify = Verify()
        
        class Verify: CoreElements {
            @discardableResult
            func changeDefaultAddressViewShown(_ email: String) -> DefaultEmailAddressRobot {
                button(email).waitUntilExists().checkExists()
                return DefaultEmailAddressRobot()
            }
        }
    }

    /**
     Contains all the validations that can be performed by AccountSettingsRobot.
     */
    class Verify: CoreElements {
        
        func accountSettingsOpened() {}
        
        @discardableResult
        func signatureIsEnabled() -> AccountSettingsRobot {
            staticText(id.signatureRightStaticTextIdentifier).hasLabel(id.onStaticTextLabel).checkExists()
            return AccountSettingsRobot()
        }
        
        @discardableResult
        func signatureIsDisabled() -> AccountSettingsRobot {
            staticText(id.signatureRightStaticTextIdentifier).hasLabel(id.offStaticTextLabel).checkExists()
            return AccountSettingsRobot()
        }
        
        @discardableResult
        func mobileSignatureIsEnabled() -> AccountSettingsRobot {
            staticText(id.mobileSignatureRightStaticTextIdentifier).hasLabel(id.onStaticTextLabel).checkExists()
            return AccountSettingsRobot()
        }
        
        @discardableResult
        func mobileSignatureIsDisabled() -> AccountSettingsRobot {
            staticText(id.mobileSignatureRightStaticTextIdentifier).hasLabel(id.offStaticTextLabel).checkExists()
            return AccountSettingsRobot()
        }
        
        @discardableResult
        func displayNameShownWithText(_ name: String) -> AccountSettingsRobot {
            staticText(name).waitUntilExists().checkExists()
            return AccountSettingsRobot()
        }
        
        @discardableResult
        func deleteAccountShown() -> AccountSettingsRobot {
            staticText(id.deleteAccount).waitUntilExists().checkExists()
            return AccountSettingsRobot()
        }
    }
}
