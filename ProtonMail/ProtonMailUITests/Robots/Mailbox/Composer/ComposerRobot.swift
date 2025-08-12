//
//  ComposerRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest
import fusion

fileprivate struct id {
    /// Composer identifiers.
    static let sendButtonIdentifier = "ComposeContainerViewController.sendButton"
    static let sendButtonLabel = "LocalString._general_send_action"
    static let toTextFieldIdentifier = "To:TextField"
    static let ccTextFieldIdentifier = "ccTextField"
    static let bccTextFieldIdentifier = "bccTextField"
    static let composerWebViewIdentifier = "ComposerBody"
    static let subjectTextFieldIdentifier = "ComposeHeaderViewController.subject"
    static let popoverDismissRegionOtherIdentifier = "PopoverDismissRegion"
    static let expirationButtonIdentifier = "ComposeContainerViewController.toolbar.hourButton"
    static let passwordButtonIdentifier = "ComposeContainerViewController.toolbar.lockButton"
    static let attachmentButtonIdentifier = "ComposeContainerViewController.toolbar.attachmentButton"
    static let cancelNavBarButtonIdentifier = "ComposeContainerViewController.cancelButton"
    static let showCcBccButtonIdentifier = "ComposeHeaderViewController.showCcBccButton"
    static let fromStaticTextIdentifier = "ComposeHeaderViewController.fromAddress"
    static let fromPickerButtonIdentifier = "ComposeHeaderViewController.fromPickerButton"
    static func getContactCellIdentifier(_ email: String) -> String { return "ContactsTableViewCell.\(email)" }
    
    static let saveDraftButtonText = "saveDraftButton"
    static let invalidAddressStaticTextIdentifier = LocalString._signle_address_invalid_error_content
    static let recipientNotFoundStaticTextIdentifier = LocalString._recipient_not_found
    
    static let setExpirationButtonLabel = LocalString._general_set
    static let messageBodyLabel = "HTML Editor"
    static let returnKeyboardButtonLabel = "return"
    
    /// Default Photo library images identifiers
    static func imageCellIdentifier(_ number: Int) -> String {
        return "ComposerAttachmentCellTableViewCell.\(imageSize[number])"
    }
    static func imageUploadingCellIdentifier(_ number: Int) -> String {
        return "ComposerAttachmentCellTableViewCell.\(imageSize[number])_uploading"
    }
    static let imageSize = ["9604853", "1852262", "1268382"]
}

/**
 Represents Composer view.
 */
class ComposerRobot: CoreElements {
    
    var verify = Verify()
    
    func tapCancel() -> InboxRobot {
        button(id.cancelNavBarButtonIdentifier).tap()
        return InboxRobot()
    }
    
    func tapCancelFromDrafts() -> DraftsRobot {
        button(id.cancelNavBarButtonIdentifier).firstMatch().tap()
        return DraftsRobot()
    }
    
    func sendMessage(_ to: String, _ subjectText: String) -> InboxRobot {
        return typeAndSelectRecipients(to)
            .subject(subjectText)
            .send()
    }
    
    func sendMessageWithSavedContact(_ to: String, _ subjectText: String) -> InboxRobot {
        return typeAndSelectRecipients(to)
            .subject(subjectText)
            .send()
    }
    
    func draftToSubjectBody(_ to: String, _ subjectText: String, _ body: String) -> ComposerRobot {
        recipients(to)
            .subject(subjectText)
            .body(body)
        return self
    }
    
    func draftToBody(_ to: String, _ body: String) -> ComposerRobot {
        recipients(to)
            .body(body)
        return self
    }
    
    func draftSubjectBody(_ subjectText: String, _ body: String) -> ComposerRobot {
        subject(subjectText)
            .body(body)
        return self
    }
    
    func draftToSubjectBodyAttachment(_ to: String, _ subjectText: String, _ body: String) -> ComposerRobot {
        return recipients(to)
            .addAttachment()
            .add()
            .pickImages(1)
            .subject(subjectText)
            .body(body)
        
    }
    
    func sendMessageToContact(_ subjectText: String) -> ContactDetailsRobot {
        return subject(subjectText)
            .sendToContact()
    }
    
    func sendMessageToGroup(_ subjectText: String) -> ContactsRobot {
        return subject(subjectText)
            .sendToContactGroup()
    }
    
    func sendMessage(_ to: String, _ cc: String, _ subjectText: String) -> InboxRobot {
        return recipients(to)
            .cc(cc)
            .subject(subjectText)
            .send()
    }
    
    func sendMessage(_ to: String, _ cc: String, _ bcc: String, _ subjectText: String) -> InboxRobot {
        return typeAndSelectRecipients(to)
            .showCcBcc()
            .cc(cc)
            .bcc(bcc)
            .subject(subjectText)
            .send()
    }
    
    func sendMessageWithPassword(_ to: String, _ subjectText: String, _ body: String, _ password: String, _ hint: String) -> InboxRobot {
        return composeMessage(to, subjectText, body)
            .setMessagePassword()
            .definePasswordWithHint(password, hint)
            .send()
    }
    
    func sendMessageExpiryTimeInDays(_ to: String, _ subjectText: String, _ body: String, expirePeriod: expirationPeriod) -> InboxRobot {
        recipients(to)
            .subject(subjectText)
            .messageExpiration()
            .setExpiration(expirePeriod)
            .send()
        return InboxRobot()
    }
    
    func sendMessageEOAndExpiryTime(_ to: String, _ subjectText: String, _ password: String, _ hint: String, expirePeriod: expirationPeriod) -> InboxRobot {
        recipients(to)
            .subject(subjectText)
            .setMessagePassword()
            .definePasswordWithHint(password, hint)
            .messageExpiration()
            .setExpiration(expirePeriod)
            .send()
        return InboxRobot()
    }
    
    func sendMessageWithAttachments(_ to: String, _ subjectText: String, attachmentsAmount: Int = 1) -> InboxRobot {
        addAttachment()
            .add()
            .pickImages(attachmentsAmount)
            .typeAndSelectRecipients(to)
            .subject(subjectText)
            .send()
        return InboxRobot()
    }
    
    func sendMessageEOAndExpiryTimeWithAttachment(_ to: String, _ subjectText: String, _ password: String, _ hint: String, attachmentsAmount: Int = 1, expirePeriod: expirationPeriod) -> InboxRobot {
        addAttachment()
            .add()
            .pickImages(attachmentsAmount)
            .recipients(to)
            .subject(subjectText)
            .setMessagePassword()
            .definePasswordWithHint(password, hint)
            .messageExpiration()
            .setExpiration(expirePeriod)
            .send()
        return InboxRobot()
    }
    
    @discardableResult
    func send() -> InboxRobot {
        button(id.sendButtonIdentifier).waitForHittable().tap()
        return InboxRobot()
    }
    
    @discardableResult
    func sendMessageFromMessageRobot() -> MessageRobot {
        send()
        return MessageRobot()
    }
    
    func recipients(_ email: String) -> ComposerRobot {
        textField(id.toTextFieldIdentifier).tap().typeText(email)
        button("Return").firstMatch().tap()
        return self
    }
    
    func typeAndSelectRecipients(_ email: String) -> ComposerRobot {
        textField(id.toTextFieldIdentifier).firstMatch().tap().typeText(email)
        if cell(id.getContactCellIdentifier(email.replaceSpaces())).firstMatch().exists() {
            cell(id.getContactCellIdentifier(email.replaceSpaces())).firstMatch().waitForHittable().tap()
        } else {
            otherElement(id.messageBodyLabel).tap()
        }
        return self
    }
    
    func editRecipients(_ email: String) -> ComposerRobot {
        textField(id.toTextFieldIdentifier).tap().typeText(email)
        keyboard().byIndex(0).onDescendant(button("Return")).firstMatch().tap()
        return self
    }
    
    func changeFromAddressTo(_ email: String) -> ComposerRobot {
        button(id.fromPickerButtonIdentifier).tap()
        button(email).waitForHittable().tap()
        return ComposerRobot()
    }
    
    func changeSubjectTo(_ subjectText: String) -> ComposerRobot {
        textField(id.subjectTextFieldIdentifier)
            .firstMatch()
            .waitForHittable().tapOnCoordinate(withOffset: CGVector(dx: 0.99, dy: 0.99))
            .clearText().typeText(subjectText)
        return ComposerRobot()
    }
    
    func changeBodyTo(_ body: String) -> ComposerRobot {
        textField(id.subjectTextFieldIdentifier).clearText().typeText(body)
        return ComposerRobot()
    }
    
    private func sendToContact() -> ContactDetailsRobot {
        button(id.sendButtonIdentifier).waitForHittable().tap()
        return ContactDetailsRobot()
    }
    
    private func sendToContactGroup() -> ContactsRobot {
        button(id.sendButtonIdentifier).waitForHittable().tap()
        return ContactsRobot()
    }
    
    private func cc(_ email: String) -> ComposerRobot {
        textField(id.ccTextFieldIdentifier).tap().typeText(email)
        return self
    }
    
    func typeAndSelectCC(_ email: String) -> ComposerRobot {
        textField(id.ccTextFieldIdentifier).tap().typeText(email)
        cell(id.getContactCellIdentifier(email)).tap()
        return self
    }
    
    private func bcc(_ email: String) -> ComposerRobot {
        textField(id.bccTextFieldIdentifier).tap().typeText(email)
        return self
    }
    
    func typeAndSelectBCC(_ email: String) -> ComposerRobot {
        textField(id.bccTextFieldIdentifier).tap().tap().typeText(email)
        cell(id.getContactCellIdentifier(email)).tap()
        return self
    }
    
    func tapSubject() -> ComposerRobot {
        textField(id.subjectTextFieldIdentifier).waitForEnabled().waitForHittable().tap()
        return self
    }
    
    func tapBody() -> ComposerRobot {
        webView(id.composerWebViewIdentifier).tap()
        return self
    }
    
    func subject(_ subjectText: String) -> ComposerRobot {
        textField(id.subjectTextFieldIdentifier)
            .firstMatch()
            .forceKeyboardFocus()
            .tap()
            .typeText(subjectText)
        button(id.returnKeyboardButtonLabel).tap()
        return self
    }
    
    @discardableResult
    private func body(_ text: String) -> ComposerRobot {
        otherElement(id.messageBodyLabel).tap().typeText(text)
        return self
    }
    
    func pasteSubject(_ subjectText: String) -> ComposerRobot {
        device().saveTextToClipboard(subjectText)
        textField(id.subjectTextFieldIdentifier).tap()
        textField(id.subjectTextFieldIdentifier).longPress()
        menuItem().byIndex(0).onChild(staticText().byIndex(0)).tap()
        return self
    }
    
    func waitForImagesUpload(_ imageCount: Int)  -> ComposerRobot {
        /// Start from image 1 as image on position 0 is 9MB and it takes longer time to upload.
        for i in 1...imageCount {
            cell(id.imageUploadingCellIdentifier(i)).waitUntilGone(time: 30)
        }
        
        return self
    }
    
    func backgroundApp() -> ComposerRobot {
        XCUIDevice.shared.press(.home)
        //It's always much more stable with a small gap between background and foreground
        sleep(3)
        return self
    }
    
    func foregroundApp() -> ComposerRobot {
        XCUIApplication().activate()
        return self
    }
    
    private func composeMessage(_ to: String, _ subject: String, _ body: String) -> ComposerRobot {
        return recipients(to)
            .subject(subject)
            .body(body)
    }
    
    private func setMessagePassword() -> SetPasswordRobot  {
        button(id.passwordButtonIdentifier).firstMatch().tap()
        return SetPasswordRobot()
    }
    
    private func addAttachment() -> MessageAttachmentsRobot  {
        button(id.attachmentButtonIdentifier).waitForHittable().tap()
        return MessageAttachmentsRobot()
    }
    
    func showCcBcc() -> ComposerRobot {
        button(id.showCcBccButtonIdentifier).tap()
        return self
    }
    
    private func messageExpiration() -> MessageExpirationRobot {
        button(id.expirationButtonIdentifier).firstMatch().tap()
        return MessageExpirationRobot()
    }
    
    /**
     Class represents Message Expiration dialog.
     */
    class DraftConfirmationRobot: CoreElements {
        func confirmDraftSaving() -> InboxRobot {
            button(id.saveDraftButtonText).tap()
            return InboxRobot()
        }
        
        func confirmDraftSavingFromDrafts() -> DraftsRobot {
            button(id.saveDraftButtonText).tap()
            return DraftsRobot()
        }
    }
    
    /**
     Contains all the validations that can be performed by ComposerRobot.
     */
    class Verify: CoreElements {
        
        func fromEmailIs(_ email: String) {
            staticText(id.fromStaticTextIdentifier).checkHasLabel(email)
        }
        
        func messageWithSubjectOpened(_ subject: String) {
            textField(id.subjectTextFieldIdentifier).checkHasValue(subject)
        }
        
        @discardableResult
        func invalidAddressToastIsShown() -> ComposerRobot {
            staticText(id.invalidAddressStaticTextIdentifier).waitUntilExists().checkExists()
            return ComposerRobot()
        }
        
        @discardableResult
        func invalidAddressToastIsNotShown() -> ComposerRobot {
            staticText(id.invalidAddressStaticTextIdentifier).waitUntilGone()
            return ComposerRobot()
        }
        
        @discardableResult
        func recipientNotFoundToastIsShown() -> ComposerRobot {
            staticText(id.recipientNotFoundStaticTextIdentifier).firstMatch().checkExists()
            return ComposerRobot()
        }
        
        @discardableResult
        func recipientNotFoundToastIsNotShown() -> ComposerRobot {
            staticText(id.recipientNotFoundStaticTextIdentifier).waitUntilGone()
            return ComposerRobot()
        }
    }
}
