//
//  ExpandedHeaderViewController.swift
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
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreDataModel
import ProtonCoreUIFoundations
import UIKit

class ExpandedHeaderViewController: UIViewController {

    private(set) lazy var customView = ExpandedHeaderView()

    private let viewModel: ExpandedHeaderViewModel
    private var hideDetailsAction: (() -> Void)?

    var contactTapped: ((MessageHeaderContactContext) -> Void)?

    init(viewModel: ExpandedHeaderViewModel) {
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
        setUpViewModelObservation()
        setUpView()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timeZoneDidChange),
            name: .NSSystemTimeZoneDidChange,
            object: nil
        )
    }

    func observeHideDetails(action: @escaping (() -> Void)) {
        self.hideDetailsAction = action
    }

    func preferredContentSizeChanged() {
        customView.preferredContentSizeChanged()
        customView.contentStackView.arrangedSubviews.forEach { row in
            if let tagView = row as? ExpandedHeaderTagView {
                let tags = viewModel.infoProvider.message.tagUIModels()
                tagView.setUp(tags: tags)
                return
            }
            guard let rowView = row as? ExpandedHeaderRowView else { return }
            rowView.titleLabel.font = .adjustedFont(forTextStyle: .footnote)
            rowView.contentStackView.arrangedSubviews.forEach { content in
                if let label = content as? UILabel {
                    label.font = .adjustedFont(forTextStyle: .footnote)
                } else if let stack = content as? UIStackView {
                    stack.arrangedSubviews.forEach { view in
                        guard let control = view as? TextControl else { return }
                        control.label.font = .adjustedFont(forTextStyle: .footnote)
                    }
                } else if let button = view as? UIButton {
                    button.titleLabel?.font = .adjustedFont(forTextStyle: .footnote)
                }
            }
        }
    }

    private func setUpViewModelObservation() {
        viewModel.reloadView = { [weak self] in
            self?.setUpView()
        }
    }

    private func setUpView() {
        customView.contentStackView.clearAllViews()

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

        customView.senderLabel.set(
            text: viewModel.infoProvider.senderName,
            preferredFont: .subheadline,
            weight: .semibold,
            lineBreakMode: .byTruncatingMiddle
        )

        customView.officialBadge.isHidden = viewModel.isOfficialBadgeHidden
        setTimeString()

        customView.senderEmailControl.label.set(text: viewModel.infoProvider.senderEmail,
                                                preferredFont: .footnote,
                                                textColor: ColorProvider.InteractionNorm,
                                                lineBreakMode: .byTruncatingMiddle)

        customView.starImageView.isHidden = !viewModel.infoProvider.message.isStarred

        customView.senderEmailControl.tap = { [weak self] in
            guard let sender = self?.viewModel.infoProvider.checkedSenderContact else { return }
            self?.contactTapped?(.sender(sender.sender))
        }

        var contactRow: ExpandedHeaderRowView?
        if let toData = viewModel.infoProvider.toData {
            contactRow = present(viewModel: toData, doNotCoverMoreButton: true)
        }

        if let ccData = viewModel.infoProvider.ccData {
            let doNotCoverMoreButton = viewModel.infoProvider.toData == nil
            contactRow = present(viewModel: ccData, doNotCoverMoreButton: doNotCoverMoreButton)
        }

        if viewModel.infoProvider.message.contains(location: LabelLocation.hiddenSent),
           let bccData = viewModel.infoProvider.bccData {
            let doNotCoverMoreButton = viewModel.infoProvider.toData == nil && viewModel.infoProvider.ccData == nil
            contactRow = present(viewModel: bccData, doNotCoverMoreButton: doNotCoverMoreButton)
        }

        if viewModel.infoProvider.toData == nil && viewModel.infoProvider.ccData == nil {
            contactRow = present(viewModel: .undisclosedRecipients)
        }

        if let rowView = contactRow {
            customView.contentStackView.setCustomSpacing(18, after: rowView)
        }

        let tags = viewModel.infoProvider.message.tagUIModels()
        tags.isEmpty ? (): presentTags()

        if let fullDate = viewModel.infoProvider.date {
            presentFullDateRow(stringDate: fullDate)
        }

        if let image = viewModel.infoProvider.originImage(isExpanded: true),
            let title = viewModel.infoProvider.originFolderTitle(isExpanded: true) {
            presentOriginRow(image: image, title: title)
        }
        customView.isUserInteractionEnabled = true
        presentSizeRow(size: viewModel.infoProvider.size)

        if let (title, trackersFound) = viewModel.trackerProtectionRowInfo {
            presentTrackerProtectionRow(title: title, trackersFound: trackersFound)
        }

        let contact = viewModel.infoProvider.checkedSenderContact
        if let icon = contact?.encryptionIconStatus?.icon,
           let iconColor = contact?.encryptionIconStatus?.iconColor.color,
           let reason = contact?.encryptionIconStatus?.text {
            presentLockIconRow(icon: icon, iconColor: iconColor, reason: reason)
        }
        presentHideDetailButton()
        setUpLock()
    }

    private func setTimeString() {
        customView.timeLabel.set(text: viewModel.infoProvider.time,
                                 preferredFont: .footnote,
                                 textColor: ColorProvider.TextWeak)
    }

    private func setUpLock() {
        guard customView.lockImageView.image == nil,
              viewModel.infoProvider.message.isDetailDownloaded,
              let contact = viewModel.infoProvider.checkedSenderContact else { return }

        if let iconStatus = contact.encryptionIconStatus {
            self.customView.lockImageView.tintColor = iconStatus.iconColor.color
            self.customView.lockImageView.image = iconStatus.icon
            self.customView.lockContainer.isHidden = false
        }
    }

    private func presentTags() {
        let tags = viewModel.infoProvider.message.tagUIModels()
        guard !tags.isEmpty else { return }
        let tagViews = ExpandedHeaderTagView(frame: .zero)
        tagViews.setUp(tags: tags)
        customView.contentStackView.addArrangedSubview(tagViews)
    }

    private func present(viewModel: ExpandedHeaderRecipientsRowViewModel, doNotCoverMoreButton: Bool = false) -> ExpandedHeaderRowView {
        let row = ExpandedHeaderRowView()
        row.iconImageView.isHidden = true
        row.titleLabel.text = viewModel.title
        row.contentStackView.spacing = 5

        viewModel.recipients.enumerated().map { dataSet -> UIStackView in
            let recipient = dataSet.element
            let control = TextControl()
            control.label.set(text: recipient.name,
                              preferredFont: .footnote)
            control.label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            let addressController = TextControl()
            addressController.label.set(text: recipient.address,
                                        preferredFont: .footnote,
                                        textColor: ColorProvider.InteractionNorm,
                                        lineBreakMode: .byTruncatingMiddle)
            addressController.label.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
            if let contact = recipient.contact {
                control.tap = { [weak self] in
                    self?.contactTapped?(.recipient(contact))
                }
                addressController.tap = { [weak self] in
                    self?.contactTapped?(.recipient(contact))
                }
            }
            let stack = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center, spacing: 4)
            stack.addArrangedSubview(control)
            stack.addArrangedSubview(addressController)
            if dataSet.offset == 0 && doNotCoverMoreButton {
                // 32 reply button + 8 * 2 spacing + 32 more button
                stack.setCustomSpacing(80, after: addressController)
            }
            stack.addArrangedSubview(UIView())
            return stack
        }.forEach {
            row.contentStackView.addArrangedSubview($0)
        }
        if row.contentStackView.arrangedSubviews.count == 1 {
            let padding = UIView(frame: .zero)
            row.contentStackView.addArrangedSubview(padding)
        }
        customView.contentStackView.addArrangedSubview(row)
        return row
    }

    private func presentFullDateRow(stringDate: String) {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = IconProvider.calendarToday
        let dateLabel = UILabel(frame: .zero)
        dateLabel.set(text: stringDate,
                      preferredFont: .footnote,
                      textColor: ColorProvider.TextWeak)
        row.contentStackView.addArrangedSubview(dateLabel)
        customView.contentStackView.addArrangedSubview(row)
    }

    private func presentOriginRow(image: UIImage, title: String) {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = image
        let titleLabel = UILabel()
        titleLabel.set(text: title,
                       preferredFont: .footnote,
                       textColor: ColorProvider.TextWeak)
        row.contentStackView.addArrangedSubview(titleLabel)
        customView.contentStackView.addArrangedSubview(row)
    }

    private func presentSizeRow(size: String) {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = IconProvider.filingCabinet
        let titleLabel = UILabel()
        titleLabel.set(text: size,
                       preferredFont: .footnote,
                       textColor: ColorProvider.TextWeak)
        row.contentStackView.addArrangedSubview(titleLabel)
        customView.contentStackView.addArrangedSubview(row)
    }

    private func presentTrackerProtectionRow(title: String, trackersFound: Bool) {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = trackersFound ? IconProvider.shieldFilled : IconProvider.shield
        row.iconImageView.tintColor = ColorProvider.IconAccent

        row.contentStackView.axis = .horizontal

        let titleLabel = UILabel()
        titleLabel.set(text: title, preferredFont: .footnote, textColor: ColorProvider.TextWeak)
        titleLabel.isUserInteractionEnabled = true
        row.contentStackView.addArrangedSubview(titleLabel)

        row.contentStackView.addArrangedSubview(UIView())

        let chevronImageView = UIImageView()
        chevronImageView.image = IconProvider.chevronRightFilled
        chevronImageView.tintColor = ColorProvider.IconNorm
        chevronImageView.contentMode = .scaleAspectFit
        [
            chevronImageView.heightAnchor.constraint(equalToConstant: 16).setPriority(as: .defaultHigh)
        ].activate()
        chevronImageView.isUserInteractionEnabled = true
        row.contentStackView.addArrangedSubview(chevronImageView)

        let button = UIButton()
        button.addTarget(self, action: #selector(trackerInfoTapped), for: .touchUpInside)
        row.addSubview(button)
        button.fillSuperview()
        button.isUserInteractionEnabled = true

        customView.contentStackView.addArrangedSubview(row)
    }

    private func presentLockIconRow(icon: UIImage, iconColor: UIColor, reason: String) {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = icon.withRenderingMode(.alwaysTemplate)
        row.iconImageView.tintColor = iconColor
        let titleLabel = UILabel()
        titleLabel.set(text: reason,
                       preferredFont: .footnote,
                       textColor: ColorProvider.TextWeak)
        row.contentStackView.addArrangedSubview(titleLabel)
        customView.contentStackView.addArrangedSubview(row)
    }

    private func presentHideDetailButton() {
        let button = customView.hideDetailButton
        let stack = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center)
        let padding = UIView(frame: .zero)
        stack.addArrangedSubview(padding)
        stack.addArrangedSubview(button)
        stack.addArrangedSubview(UIView())
        [
            padding.widthAnchor.constraint(equalToConstant: 38)
        ].activate()
        customView.contentStackView.addArrangedSubview(stack)
        button.addTarget(self, action: #selector(self.clickHideDetailsButton), for: .touchUpInside)
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

    @objc
    private func trackerInfoTapped() {
        if
            let trackerProtectionSummary = viewModel.infoProvider.trackerProtectionSummary,
            !trackerProtectionSummary.trackers.isEmpty {
            let trackerList = TrackerListViewController(trackerProtectionSummary: trackerProtectionSummary)
            navigationController?.pushViewController(trackerList, animated: true)
        } else {
            let messageComponents: [String] = [
                L10n.EmailTrackerProtection.email_trackers_can_violate_your_privacy,
                String.localizedStringWithFormat(L10n.EmailTrackerProtection.proton_found_n_trackers_on_this_message, 0)
            ]
            let alert = UIAlertController(
                title: L10n.EmailTrackerProtection.no_email_trackers_found,
                message: messageComponents.joined(separator: " "),
                preferredStyle: .alert
            )
            let url = URL(string: Link.emailTrackerProtection)!
            alert.addURLAction(title: LocalString._learn_more, url: url)
            alert.addOKAction()
            present(alert, animated: true)
        }
    }

    @objc
    func clickHideDetailsButton() {
        self.hideDetailsAction?()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

extension ExpandedHeaderViewController: HeaderViewController {
    func trackerProtectionSummaryChanged() {
        setUpView()
    }
}
