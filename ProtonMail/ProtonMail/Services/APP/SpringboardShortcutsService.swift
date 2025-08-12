//
//  SpringboardShortcutsService.swift
//  Proton Mail - Created on 06/08/2019.
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
import ProtonCoreUIFoundations
import UIKit

class SpringboardShortcutsService: NSObject {
    enum QuickActions: String, CaseIterable {
        case search, favorites, compose

        var deeplink: DeepLink {
            let deeplink = DeepLink(String(describing: MenuViewController.self))

            switch self {
            case .search:
                deeplink.append(mailboxNode(location: .inbox))
                deeplink.append(.init(name: String(describing: SearchViewController.self)))
            case .favorites:
                deeplink.append(mailboxNode(location: .starred))
            case .compose:
                deeplink.append(mailboxNode(location: .inbox))
                deeplink.append(DeepLink.Node(name: String(describing: ComposeContainerViewController.self)))
            }

            return deeplink
        }

        var localization: String {
            switch self {
            case .search:
                return LocalString._springboard_shortcuts_search
            case .favorites:
                return LocalString._menu_starred_title
            case .compose:
                return LocalString._springboard_shortcuts_composer
            }
        }

        var icon: UIApplicationShortcutIcon {
            switch self {
            case .search:
                return .init(templateImageName: "ic-magnifier")
            case .favorites:
                return .init(templateImageName: "ic-star-filled")
            case .compose:
                return .init(templateImageName: "ic-pen-square")
            }
        }

        private func mailboxNode(location: Message.Location) -> DeepLink.Node {
            DeepLink.Node(
                name: String(describing: MailboxViewController.self),
                value: location
            )
        }
    }

    typealias Dependencies = HasUsersManager

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        super.init()

        self.updateShortcuts()

        NotificationCenter.default.addObserver(forName: .didSignIn, object: nil, queue: nil, using: { [weak self] _ in
            self?.addShortcuts()
        })
        NotificationCenter.default.addObserver(
            forName: .didSignOutLastAccount,
            object: nil,
            queue: nil,
            using: { [weak self] _ in
                self?.removeShortcuts()
            }
        )

        trackLifetime()
    }

    private func updateShortcuts() {
        if dependencies.usersManager.hasUsers() {
            self.addShortcuts()
        } else {
            self.removeShortcuts()
        }
    }

    private func addShortcuts() {
        UIApplication.shared.shortcutItems = QuickActions.allCases.compactMap {
            guard let deeplink = try? JSONEncoder().encode($0.deeplink) else {
                assert(false, "Broken springboard shortcut item at \(#file):\(#line)")
                return nil
            }
            return UIMutableApplicationShortcutItem(type: $0.rawValue,
                                                    localizedTitle: $0.localization,
                                                    localizedSubtitle: nil,
                                                    icon: $0.icon,
                                                    userInfo: ["deeplink": deeplink as NSSecureCoding])
        }
    }

    private func removeShortcuts() {
        UIApplication.shared.shortcutItems = []
    }
}

extension SpringboardShortcutsService: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
