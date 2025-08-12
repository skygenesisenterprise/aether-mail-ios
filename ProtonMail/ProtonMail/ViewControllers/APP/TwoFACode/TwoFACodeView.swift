//
//  2FACodeView.swift
//  Proton Mail - Created on 11/3/16.
//
//
//  Copyright (c) 2019 Proton AG
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
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

protocol TwoFACodeViewDelegate {
    func ConfirmedCode(_ code: String)
    func Cancel()
}

enum AuthMode: Int {
    case loginPassword = 0x01
    case twoFactorCode = 0x02
    case pwdAnd2FA = 0x03   // LoginPassword | TwoFactorCode

    func check(_ check: AuthMode) -> Bool {
        if self.rawValue & check.rawValue == check.rawValue {
            return true
        }
        return false
    }
}

class TwoFACodeView: PMView {

    var delegate: TwoFACodeViewDelegate?
    var mode: AuthMode!

    @IBOutlet weak var pwdTop: NSLayoutConstraint! // 18
    @IBOutlet weak var pwdHeight: NSLayoutConstraint! // 40

    @IBOutlet weak var twofacodeTop: NSLayoutConstraint! // 18
    @IBOutlet weak var twofacodeHeight: NSLayoutConstraint! // 40

    @IBOutlet weak var twoFactorCodeField: TextInsetTextField!
    @IBOutlet weak var loginPasswordField: TextInsetTextField!

    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var enterButton: UIButton!

    func initViewMode(_ mode: AuthMode) {
        self.mode = mode

        if mode.check(.loginPassword) {
            pwdTop.constant = 18.0
            pwdHeight.constant = 40.0
        } else {
            pwdTop.constant = 0.0
            pwdHeight.constant = 0.0
        }

        if mode.check(.twoFactorCode) {
            twofacodeTop.constant = 18.0
            twofacodeHeight.constant = 40.0
        } else {
            twofacodeTop.constant = 0.0
            twofacodeHeight.constant = 0.0
        }

        let toolbarDone = UIToolbar.init()
        toolbarDone.sizeToFit()
        let barBtnDone = UIBarButtonItem.init(title: LocalString._recovery_code,
                                              style: UIBarButtonItem.Style.done,
                                              target: self,
                                              action: #selector(TwoFACodeView.doneButtonAction))
        toolbarDone.items = [barBtnDone]
        twoFactorCodeField.inputAccessoryView = toolbarDone

        twoFactorCodeField.placeholder = LocalString._two_factor_code
        loginPasswordField.placeholder = L10n.AccountSettings.loginPassword
        topTitleLabel.text = LocalString._authentication
        cancelButton.setTitle(LocalString._general_cancel_button, for: .normal)
        enterButton.setTitle(LocalString._enter, for: .normal)
        generateAccessibilityIdentifiers()
    }

    @objc func doneButtonAction() {
        self.twoFactorCodeField.inputAccessoryView = nil
        self.twoFactorCodeField.keyboardType = UIKeyboardType.asciiCapable
        self.twoFactorCodeField.reloadInputViews()
    }

    override func getNibName() -> String {
        return "TwoFACodeView"
    }

    override func setup() {

    }

    func showKeyboard() {
        if mode!.check(.loginPassword) {
            _ = loginPasswordField.becomeFirstResponder()
        } else if mode!.check(.twoFactorCode) {
            _ = twoFactorCodeField.becomeFirstResponder()
        }
    }

    func confirm() {
        let code = (twoFactorCodeField.text ?? "").trim()
        if mode!.check(.loginPassword) {
            // error need
        }
        if mode!.check(.twoFactorCode) {
            // error need
        }

        self.dismissKeyboard()
        delegate?.ConfirmedCode(code)
    }

    @IBAction func enterAction(_ sender: AnyObject) {
        self.confirm()
    }

    @IBAction func cancelAction(_ sender: AnyObject) {
        self.dismissKeyboard()
        delegate?.Cancel()
    }

    func dismissKeyboard() {
        twoFactorCodeField.resignFirstResponder()
        loginPasswordField.resignFirstResponder()
    }
}
