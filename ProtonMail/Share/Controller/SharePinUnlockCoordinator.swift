//
//  SharePinUnlockCoordinator.swift
//  Share - Created on 11/4/18.
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

final class SharePinUnlockCoordinator {
    typealias VC = SharePinUnlockViewController

    weak var destinationNavigationController: UINavigationController?
    private weak var navigationController: UINavigationController?

    private var viewController: SharePinUnlockViewController?
    private let viewModel: PinCodeViewModel
    lazy var configuration: ((VC) -> Void)? = { [unowned self] vc in
        vc.viewModel = self.viewModel
    }

    init(navigation: UINavigationController, vm: PinCodeViewModel, delegate: SharePinUnlockViewControllerDelegate) {
        // parent navigation
        self.navigationController = navigation
        self.viewModel = vm
        // create self view controller
        self.viewController = SharePinUnlockViewController(nibName: "SharePinUnlockViewController", bundle: nil)
        self.viewController?.delegate = delegate
    }

    func start() {
        guard let viewController = viewController else {
            return
        }

        configuration?(viewController)
        viewController.set(coordinator: self)

        if let destinationNavigationController = destinationNavigationController {
            // wrapper navigation controller given, present it
            navigationController?.present(destinationNavigationController, animated: true, completion: nil)
        } else {
            // no wrapper navigation controller given, present actual controller
            navigationController?.present(viewController, animated: true, completion: nil)
        }
    }
}
