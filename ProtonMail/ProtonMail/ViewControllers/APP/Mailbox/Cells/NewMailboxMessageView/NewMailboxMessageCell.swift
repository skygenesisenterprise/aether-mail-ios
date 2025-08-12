//
//  NewMailboxMessageCell.swift
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

import ProtonCoreFoundations
import ProtonCoreUIFoundations
import SwipyCell
import UIKit

protocol NewMailboxMessageCellDelegate: AnyObject {
    func didSelectButtonStatusChange(cell: NewMailboxMessageCell)
    func didSelectAttachment(cell: NewMailboxMessageCell, index: Int)
}

class NewMailboxMessageCell: SwipyCell, AccessibleCell {

    weak var cellDelegate: NewMailboxMessageCellDelegate?
    private var shouldUpdateTime: Bool = false

    var mailboxItem: MailboxItem?
    var swipeActions: [SwipyCellDirection: MessageSwipeAction] = [:]

    private var workItem: DispatchWorkItem?

    let customView = NewMailboxMessageCellContentView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        customView.selectAttachmentAction = { [weak self] index in
            self?.didSelectAttachment(at: index)
        }
        addSubviews()
        setUpLayout()
        setUpAvatarTapHandling()
    }

    func resetCellContent() {
        shouldUpdateTime = false
        mailboxItem = nil
        swipeActions.removeAll()
        workItem?.cancel()
        workItem = nil

        customView.initialsLabel.attributedText = nil
        customView.initialsLabel.isHidden = false
        customView.senderImageView.isHidden = true
        customView.senderImageView.image = nil
        customView.initialsContainer.isHidden = false
        customView.scheduledIconView.isHidden = true
        customView.scheduledContainer.isHidden = true
        customView.checkBoxView.isHidden = true
        customView.messageContentView.tagsView.tagViews = []
        customView.messageContentView.removeTagsView()
        customView.messageContentView.forwardImageView.isHidden = false
        customView.messageContentView.tintColor = ColorProvider.IconWeak
        customView.messageContentView.replyImageView.isHidden = false
        customView.messageContentView.replyImageView.tintColor = ColorProvider.IconWeak
        customView.messageContentView.replyAllImageView.isHidden = false
        customView.messageContentView.replyAllImageView.tintColor = ColorProvider.IconWeak
        customView.messageContentView.sendersStackView.clearAllViews()
        customView.messageContentView.timeLabel.attributedText = nil
        customView.messageContentView.attachmentImageView.isHidden = false
        customView.messageContentView.starImageView.isHidden = false
        customView.messageContentView.titleLabel.attributedText = nil
        customView.messageContentView.draftImageView.isHidden = false
        customView.messageContentView.removeOriginImages()
        customView.messageContentView.messageCountLabel.isHidden = false
        customView.messageContentView.attachmentsPreviewStackView.clearAllViews()
        customView.messageContentView.remainingAttachmentsLabel.text = nil
        customView.messageContentView.snoozeTimeStackView.isHidden = true
    }

    func startUpdateExpiration() {
        shouldUpdateTime = true
        getExpirationOffset()
    }

    private func getExpirationOffset() {
        let workItem = DispatchWorkItem { [weak self] in
            if self?.shouldUpdateTime == true,
               let mailboxItem = self?.mailboxItem,
               let expiration = mailboxItem.expirationTime?.countExpirationTime(processInfo: userCachedStatus) {
                let tag = self?.customView.messageContentView.tagsView.tagViews.compactMap({ $0 as? TagIconView })
                    .first(where: { $0.imageView.image == IconProvider.hourglass })
                if tag?.tagLabel.text != expiration {
                    tag?.tagLabel.text = expiration
                }
                self?.getExpirationOffset()
            } else {
                self?.shouldUpdateTime = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: workItem)
        self.workItem = workItem
    }

    private func addSubviews() {
        contentView.addSubview(customView)
    }

    private func setUpLayout() {
        customView.translatesAutoresizingMaskIntoConstraints = false
        [
            customView.topAnchor.constraint(equalTo: contentView.topAnchor),
            customView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
            .activate()
    }

    private func setUpAvatarTapHandling() {
        customView.leftContainer.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
    }

    @objc
    private func avatarTapped() {
        cellDelegate?.didSelectButtonStatusChange(cell: self)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let point = gesture.location(in: self)
        guard point.x > 55 else {
            // Ignore gesture for showing the menu
            return false
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    private func didSelectAttachment(at index: Int) {
        cellDelegate?.didSelectAttachment(cell: self, index: index)
    }
}
