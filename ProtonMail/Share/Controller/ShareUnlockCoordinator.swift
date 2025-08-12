//
//  ShareUnlockCoordinator.swift
//  Share - Created on 10/31/18.
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

final class ShareUnlockCoordinator {
    typealias Dependencies = ShareUnlockViewController.Dependencies
    & ShareUnlockPinCodeModelImpl.Dependencies
    & HasUsersManager
    & HasUnlockService

    private var viewController: ShareUnlockViewController?
    private var nextCoordinator: SharePinUnlockCoordinator?

    internal weak var navigationController: UINavigationController?
    private let dependencies: Dependencies

    enum Destination: String {
        case pin, composer
    }

    init(navigation: UINavigationController?, dependencies: Dependencies) {
        // parent navigation
        self.navigationController = navigation
        self.dependencies = dependencies
        // create self view controller
        self.viewController = ShareUnlockViewController(dependencies: dependencies)
    }

    func start() {
        guard let viewController = viewController else { return }
        viewController.set(coordinator: self)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func goPin() {
        // UI refe
        guard let navigationController = self.navigationController else { return }
        let pinView = SharePinUnlockCoordinator(
            navigation: navigationController,
            vm: ShareUnlockPinCodeModelImpl(dependencies: dependencies),
            delegate: self
        )
        self.nextCoordinator = pinView
        pinView.start()
    }

    private func gotoComposer() {
        guard let controller = self.viewController,
              let navigationController = self.navigationController,
              let user = dependencies.usersManager.firstUser else {
            return
        }

        let composer = user.container.composerViewFactory.makeComposer(
            subject: controller.inputSubject,
            body: controller.inputContent,
            files: controller.files,
            navigationViewController: navigationController
        )
        navigationController.setViewControllers([composer], animated: true)

        if let error = controller.localized_errors.first {
            error.alertToast(view: composer.view)
        }
    }

    @MainActor
    func go(dest: Destination) {
        switch dest {
        case .pin:
            self.goPin()
        case .composer:
            self.gotoComposer()
        }
    }
}

extension ShareUnlockCoordinator: SharePinUnlockViewControllerDelegate {

    func onUnlockChallengeSuccess() {
        Task {
            let appAccess = await dependencies.unlockService.start()
            guard appAccess == .accessGranted else {
                SystemLogger.log(message: "Access denied after successful unlock", category: .appLock, isError: true)
                return
            }
            await go(dest: .composer)
        }
    }

    func cancel() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            fatalError("Should have value")
        }
        let users = dependencies.usersManager
        users.clean().done { [weak self] _ in
            let error = NSError(domain: bundleID, code: 0)
            self?.viewController?.extensionContext?.cancelRequest(withError: error)
        }.cauterize()
    }
}
