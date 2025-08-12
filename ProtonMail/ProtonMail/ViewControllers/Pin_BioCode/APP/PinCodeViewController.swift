//
//  PinCodeViewController.swift
//  Proton Mail - Created on 4/6/16.
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

import LifetimeTracker
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

protocol PinCodeViewControllerDelegate: AnyObject {
    func onUnlockChallengeSuccess()
    func cancel(completion: @escaping () -> Void)
}

final class PinCodeViewController: UIViewController, AccessibleView, LifetimeTrackable {
    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    private let viewModel: PinCodeViewModel
    var notificationToken: NSObjectProtocol?
    private weak var delegate: PinCodeViewControllerDelegate?

    private lazy var pinCodeView: PinCodeView = .init()
    private let contentView = UIView()
    let unlockManager: UnlockManager

    init(unlockManager: UnlockManager,
         viewModel: PinCodeViewModel,
         delegate: PinCodeViewControllerDelegate?) {
        self.unlockManager = unlockManager
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        trackLifetime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = self.contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        view.backgroundColor = ColorProvider.BackgroundNorm

        self.setUpView(true)
        self.setupPinCodeView()
        self.subscribeToWillEnterForegroundMessage()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        generateAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.layoutIfNeeded()

        if self.viewModel.checkTouchID() {
            if unlockManager.cacheStatus.isTouchIDEnabled {
                self.decideOnBioAuthentication()
            }
        }

        if self.viewModel.getPinFailedRemainingCount() < 4 {
            self.pinCodeView.showAttemptError(self.viewModel.getPinFailedError(), low: true)
        }
    }

    private func setupPinCodeView() {
        self.pinCodeView.delegate = self
        self.contentView.addSubview(self.pinCodeView)
        [
            self.pinCodeView.topAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor),
            self.pinCodeView.trailingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.trailingAnchor),
            self.pinCodeView.leadingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.leadingAnchor),
            self.pinCodeView.bottomAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.bottomAnchor)
        ].activate()

    }

    private func setUpView(_ reset: Bool) {
        self.pinCodeView.updateViewText(cancelText: self.viewModel.cancel(),
                                        resetPin: reset)
        self.pinCodeView.updateBackButton(self.viewModel.backButtonIcon())
    }

    @objc
    private func didEnterBackground() {
        DispatchQueue.main.async {
            self.pinCodeView.resetPin()
        }
    }
}

extension PinCodeViewController: BioAuthenticating {
    func authenticateUser() {
        unlockManager.biometricAuthentication(afterBioAuthPassed: {
            self.viewModel.done { shouldPop in
                self.delegate?.onUnlockChallengeSuccess()
                if shouldPop {
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
        })
    }
}

extension PinCodeViewController: PinCodeViewDelegate {
    func cancel() {
        guard self.viewModel.needsLogoutConfirmation() else {
            self.proceedCancel()
            return
        }

        let alert = UIAlertController(
            title: nil,
            message: LocalString._signout_secondary_account_from_manager_account,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: LocalString._sign_out, style: .destructive, handler: self.proceedCancel))
        alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func proceedCancel(_ sender: Any? = nil) {
        guard let delegate = self.delegate else {
            // Pin code settings
            self.navigationController?.popViewController(animated: true)
            return
        }

        // unlock when app launch
        delegate.cancel {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }

    func next(_ code: String) {
        if code.isEmpty {
            let alert = LocalString._pin_code_cant_be_empty.alertController()
            alert.addOKAction()
            present(alert, animated: true, completion: nil)
        } else {
            let step: PinCodeStep = viewModel.setCode(code)
            if step != .done {
                setUpView(true)
            } else {
                verifyPinCode()
            }
        }
    }

    private func verifyPinCode() {
        Task {
            let isVerified = await viewModel.verifyPinCode()
            updateView(validationResult: isVerified)
        }
    }

    @MainActor
    private func updateView(validationResult isPinCodeValid: Bool) {
        if isPinCodeValid {
            pinCodeView.hideAttemptError(true)
            viewModel.done { [unowned self] shouldPop in
                self.delegate?.onUnlockChallengeSuccess()
                if shouldPop {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        } else {
            let remainingCount = viewModel.getPinFailedRemainingCount()
            if remainingCount == 11 { // when setup
                pinCodeView.resetPin()
                pinCodeView.showAttemptError(viewModel.getPinFailedError(), low: false)
            } else if remainingCount < 10 {
                if remainingCount <= 0 {
                    proceedCancel()
                } else {
                    pinCodeView.resetPin()
                    pinCodeView.showAttemptError(
                        viewModel.getPinFailedError(),
                        low: remainingCount < 4
                    )
                }
            }
            pinCodeView.showError()
        }
    }
}
