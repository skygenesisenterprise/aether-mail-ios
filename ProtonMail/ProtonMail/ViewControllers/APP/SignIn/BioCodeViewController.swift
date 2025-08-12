//
//  BioCodeViewController.swift
//  Proton Mail - Created on 19/09/2019.
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

import Foundation
import ProtonCoreUIFoundations
import UIKit

final class BioCodeViewController: UIViewController, BioCodeViewDelegate {
    weak var delegate: PinCodeViewControllerDelegate?
    var bioCodeView: BioCodeView?
    var notificationToken: NSObjectProtocol?
    let unlockManager: UnlockManager

    init(unlockManager: UnlockManager,
         delegate: PinCodeViewControllerDelegate) {
        self.unlockManager = unlockManager
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let token = self.notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    private func addSubviews() {
        let view = BioCodeView(frame: .zero)
        self.bioCodeView = view
        self.view.addSubview(view)
    }

    private func setupLayout() {
        self.bioCodeView?.fillSuperview()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.addSubviews()
        self.setupLayout()
        self.configureNavigationBar()
        self.view.backgroundColor = ColorProvider.BackgroundNorm
        self.bioCodeView?.delegate = self
        self.bioCodeView?.setup()
        self.bioCodeView?.loginCheck(.requireTouchID)

        self.subscribeToWillEnterForegroundMessage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.decideOnBioAuthentication()
    }

    private func configureNavigationBar() {
        let original = IconProvider.arrowOutFromRectangle
            .withRenderingMode(.alwaysTemplate)

        self.navigationItem.title = ""
        let logoutButton = UIBarButtonItem(image: original,
                                           style: .plain,
                                           target: self,
                                           action: #selector(self.logoutButtonTapped))
        logoutButton.tintColor = ColorProvider.IconNorm
        self.navigationItem.leftBarButtonItem = logoutButton

        if let bar = self.navigationController?.navigationBar {
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.tintColor = .white
            bar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: Fonts.h2.regular
            ]
        }
    }

    @objc
    private func logoutButtonTapped() {
        let alert = UIAlertController(title: nil,
                                      message: LocalString._signout_confirmation_in_bio,
                                      preferredStyle: .alert)
        let logout = UIAlertAction(title: LocalString._sign_out,
                                   style: .destructive) { [weak self] _ in
            self?.logout()
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_button,
                                   style: .cancel,
                                   handler: nil)
        [logout, cancel].forEach(alert.addAction)
        self.present(alert, animated: true, completion: nil)
    }

    private func logout() {
        self.delegate?.cancel { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
}

extension BioCodeViewController: BioAuthenticating {
    func authenticateUser() {
        guard UIDevice.current.biometricType != .none else {
            let bioType = UIDevice.hasPhysicalHome ? "Touch ID" : "Face ID"
            let message = String.localizedStringWithFormat(
                LocalString._enable_faceid_in_settings,
                bioType,
                bioType,
                bioType
            )
            let alert = UIAlertController(title: LocalString._unlock_required,
                                          message: message,
                                          preferredStyle: .alert)
            let settings = UIAlertAction(title: LocalString._go_to_settings, style: .cancel) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                UIApplication.shared.open(url)
            }
            let logout = UIAlertAction(title: LocalString._go_to_signin, style: .default) { [weak self] _ in
                self?.logout()
            }
            [settings, logout].forEach(alert.addAction)
            self.present(alert, animated: true, completion: nil)
            return
        }

        self.unlockManager.biometricAuthentication(afterBioAuthPassed: {
            if Thread.isMainThread {
                self.delegate?.onUnlockChallengeSuccess()
            } else {
                DispatchQueue.main.async {
                    self.delegate?.onUnlockChallengeSuccess()
                }
            }
        })
    }

    func touch_id_action() {
        self.authenticateUser()
    }
}
