//
//  SettingsGesturesViewController.swift
//  Proton Mail - Created on 3/17/15.
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

import ProtonCoreUIFoundations
import UIKit

class SettingsGesturesViewController: ProtonMailViewController {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var infoIconImage: UIImageView!
    @IBOutlet private var topInfoTitle: UILabel!

    private let viewModel: SettingsGestureViewModel
    private let coordinator: SettingsGesturesCoordinator

    private(set) var selectedAction: SwipeActionItems?

    init(viewModel: SettingsGestureViewModel, coordinator: SettingsGesturesCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum CellKey {
        static let cellHeight: CGFloat = 48.0
        static let displayCellHeight: CGFloat = 142.0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(SwipeActionLeftToRightTableViewCell.self)
        self.tableView.register(SwipeActionRightToLeftTableViewCell.self)
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none

        self.view.backgroundColor = ColorProvider.BackgroundNorm
        self.infoIconImage.image = IconProvider.infoCircle
        self.infoIconImage.tintColor = ColorProvider.TextWeak
        topInfoTitle.set(text: LocalString._setting_swipe_action_info_title,
                         preferredFont: .footnote,
                         textColor: ColorProvider.TextWeak)

        self.setupDismissButton()
        self.configureNavigationBar()
        self.setupDoneButton()

        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.tableView.reloadData()
    }

    private func setupDoneButton() {
        let doneBtn = UIBarButtonItem(title: LocalString._general_done_button,
                                      style: .plain,
                                      target: self,
                                      action: #selector(self.dismissView))
        let attr = FontManager.HeadlineSmall.foregroundColor( ColorProvider.InteractionNorm)
        doneBtn.setTitleTextAttributes(attr, for: .normal)
        navigationItem.rightBarButtonItem = doneBtn
    }

    private func setupDismissButton() {
        let dismissBtn = IconProvider.cross
            .toUIBarButtonItem(target: self,
                               action: #selector(self.dismissView),
                               style: .done,
                               tintColor: ColorProvider.TextNorm,
                               squareSize: 24)
        navigationItem.leftBarButtonItem = dismissBtn
    }

    private func updateTitle() {
        self.title = LocalString._swipe_actions
    }

    private func showSwipeActionList(selected: SwipeActionItems) {
        self.selectedAction = selected
        self.coordinator.go(to: .actionSelection)
    }

    @objc
    private func dismissView() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    @objc
    private func preferredContentSizeChanged() {
        topInfoTitle.font = .adjustedFont(forTextStyle: .footnote, weight: .regular)
    }
}

extension SettingsGesturesViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - table view delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.settingSwipeActionItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.viewModel.settingSwipeActionItems[indexPath.row]
        switch item {
        case .left, .right:
            if let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID,
                                                        for: indexPath) as? SettingsGeneralCell {
                cell.backgroundColor = ColorProvider.BackgroundNorm
                cell.addSeparator(padding: 0)
                switch item {
                case .left:
                    cell.configureCell(left: LocalString._swipe_right_to_left,
                                       right: self.viewModel.rightToLeftAction.selectionTitle,
                                       imageType: .arrow)
                case .right:
                    cell.configureCell(left: LocalString._swipe_left_to_right,
                                       right: self.viewModel.leftToRightAction.selectionTitle,
                                       imageType: .arrow)
                default:
                    break
                }
                return cell
            }
        case .empty:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            return cell
        case .rightActionView:
            if let cell = tableView.dequeueReusableCell(withIdentifier: SwipeActionLeftToRightTableViewCell.CellID, for: indexPath) as? SwipeActionLeftToRightTableViewCell {
                cell.selectionStyle = .none
                let action = self.viewModel.leftToRightAction
                cell.configure(icon: action.actionDisplayIcon, title: action.actionDisplayTitle, color: action.actionColor, shouldHideIcon: action == .none)
                return cell
            }
        case .leftActionView:
            if let cell = tableView.dequeueReusableCell(withIdentifier: SwipeActionRightToLeftTableViewCell.CellID, for: indexPath) as? SwipeActionRightToLeftTableViewCell {
                cell.selectionStyle = .none
                let action = self.viewModel.rightToLeftAction
                cell.configure(icon: action.actionDisplayIcon, title: action.actionDisplayTitle, color: action.actionColor, shouldHideIcon: action == .none)
                return cell
            }
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = self.viewModel.settingSwipeActionItems[indexPath.row]
        switch item {
        case .left, .right, .empty:
            return CellKey.cellHeight
        case .leftActionView, .rightActionView:
            return CellKey.displayCellHeight
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actionItem = self.viewModel.settingSwipeActionItems[indexPath.row]
        guard actionItem == .left || actionItem == .right else {
            return
        }
        self.showSwipeActionList(selected: actionItem)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
