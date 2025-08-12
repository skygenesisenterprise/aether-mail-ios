//
//  NonExpandedHeaderViewController.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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

import ProtonCoreDataModel
import ProtonCoreUIFoundations
import UIKit

class NonExpandedHeaderViewController: UIViewController {

    private(set) lazy var customView = NonExpandedHeaderView()
    private let viewModel: NonExpandedHeaderViewModel
    private let tagsPresenter = TagsPresenter()
    private var showDetailsAction: (() -> Void)?

    var contactTapped: ((MessageHeaderContactContext) -> Void)?

    init(viewModel: NonExpandedHeaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        customView.onSenderContainerTapped = { [weak self] in
            guard let sender = self?.viewModel.infoProvider.checkedSenderContact else { return }
            self?.contactTapped?(.sender(sender.sender))
        }
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpLockTapAction()
        setUpViewModelObservations()
        setUpView()
        setUpTimeLabelUpdate()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timeZoneDidChange),
            name: .NSSystemTimeZoneDidChange,
            object: nil
        )
    }

    func observeShowDetails(action: @escaping (() -> Void)) {
        self.showDetailsAction = action
    }

    private func setUpView() {
        customView.initialsLabel.set(text: viewModel.infoProvider.initials, preferredFont: .footnote)
        customView.initialsLabel.textAlignment = .center

        viewModel.fetchSenderImageIfNeeded(
            isDarkMode: isDarkMode,
            scale: currentScreenScale
        ) { [weak self] image in
            if let image = image {
                self?.customView.senderImageView.image = image
                self?.customView.initialsLabel.isHidden = true
            }
        }

        customView.originImageView.image = viewModel.infoProvider.originImage(isExpanded: false)
        customView.originImageContainer.isHidden = viewModel.infoProvider.originImage(isExpanded: false) == nil
        customView.sentImageView.superview?.isHidden = !viewModel.shouldShowSentImage
        customView.senderLabel.set(text: viewModel.infoProvider.senderName,
                                   preferredFont: .subheadline,
                                   weight: .semibold)
        customView.senderAddressLabel.label.set(text: viewModel.infoProvider.senderEmail,
                                                preferredFont: .footnote,
                                                textColor: ColorProvider.InteractionNorm,
                                                lineBreakMode: .byTruncatingMiddle)

        customView.officialBadge.isHidden = viewModel.isOfficialBadgeHidden

        setTimeString()
        customView.recipientLabel.set(
            text: viewModel.infoProvider.simpleRecipient ?? .init(string: ""),
            preferredFont: .footnote,
            textColor: ColorProvider.TextWeak
        )
        updateTrackerDetectionStatus()
        customView.expandView = { [weak self] in
            self?.showDetailsAction?()
        }
        let isStarred = viewModel.infoProvider.message.isStarred
        customView.starImageView.isHidden = !isStarred
        let tags = viewModel.infoProvider.message.tagUIModels()
        tagsPresenter.presentTags(tags: tags, in: customView.tagsView)
        let contact = viewModel.infoProvider.checkedSenderContact
        update(senderEncryptionIconStatus: contact?.encryptionIconStatus)
    }

    func updateTrackerDetectionStatus() {
        customView.showTrackerDetectionStatus(viewModel.trackerDetectionStatus)
    }

    private func update(senderEncryptionIconStatus: EncryptionIconStatus?) {
        if let senderEncryptionIconStatus = senderEncryptionIconStatus {
            customView.lockImageView.image = senderEncryptionIconStatus.icon
            customView.lockImageView.tintColor = senderEncryptionIconStatus.iconColor.color
            customView.lockContainer.isHidden = false
        } else {
            customView.lockContainer.isHidden = true
        }
    }

    private func setTimeString() {
        customView.timeLabel.set(text: viewModel.infoProvider.time,
                                 preferredFont: .footnote,
                                 textColor: ColorProvider.TextWeak)
    }

    func preferredContentSizeChanged() {
        customView.preferredContentSizeChanged()
        setUpTags()
    }

    private func setUpTags() {
        let tags = viewModel.infoProvider.message.tagUIModels()
        tagsPresenter.presentTags(tags: tags, in: customView.tagsView)
    }

	private func setUpTimeLabelUpdate() {
        viewModel.setupTimerIfNeeded()
        viewModel.updateTimeLabel = { [weak self] in
            self?.customView.timeLabel.text = self?.viewModel.infoProvider.time
        }
    }

    private func setUpLockTapAction() {
        customView.lockImageControl.addTarget(self, action: #selector(lockTapped), for: .touchUpInside)
    }

    @objc
    private func lockTapped() {
        viewModel.infoProvider.checkedSenderContact?.encryptionIconStatus?.text.alertToastBottom()
    }

    @objc
    private func timeZoneDidChange() {
        setTimeString()
    }

    private func setUpViewModelObservations() {
        viewModel.reloadView = { [weak self] in
            self?.setUpView()
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

}

extension NonExpandedHeaderViewController: HeaderViewController {
    func trackerProtectionSummaryChanged() {
        updateTrackerDetectionStatus()
    }
}
