//
//  ComposerAttachmentCellTableViewCell.swift
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

import ProtonCoreUIFoundations
import UIKit

protocol ComposerAttachmentCellDelegate: AnyObject {
    func clickDeleteButton(for objectID: String)
}

final class ComposerAttachmentCellTableViewCell: UITableViewCell {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var fileName: UILabel!
    @IBOutlet private var fileSize: UILabel!
    @IBOutlet private var deleteButton: UIButton!
    @IBOutlet private var iconView: UIImageView!
    private var objectID: String = ""
    private weak var delegate: ComposerAttachmentCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.contentView.backgroundColor = ColorProvider.BackgroundNorm
        self.containerView.roundCorner(8)
        self.containerView.layer.borderWidth = 1
        self.containerView.layer.borderColor = ColorProvider.InteractionWeak
        self.containerView.backgroundColor = ColorProvider.BackgroundNorm
        self.activityIndicator.color = ColorProvider.IconWeak
    }

    func config(objectID: String,
                name: String,
                size: Int,
                mime: String,
                isUploading: Bool,
                delegate: ComposerAttachmentCellDelegate?) {
        self.objectID = objectID
        self.deleteButton.tintColor = ColorProvider.IconNorm
        self.deleteButton.setImage(IconProvider.crossSmall, for: .normal)
        self.delegate = delegate

        let color: UIColor = isUploading ? ColorProvider.TextDisabled : ColorProvider.TextNorm
        fileName.set(text: name,
                     preferredFont: .subheadline,
                     textColor: color,
                     lineBreakMode: .byTruncatingMiddle)

        let byteCountFormatter = ByteCountFormatter()
        let sizeColor: UIColor = isUploading ? ColorProvider.TextDisabled : ColorProvider.TextHint
        fileSize.set(text: "\(byteCountFormatter.string(fromByteCount: Int64(size)))",
                     preferredFont: .footnote,
                     textColor: sizeColor)

        let attachmentType = AttachmentType(mimeType: mime)
        self.iconView.image = isUploading ? nil : attachmentType.icon
        if isUploading {
            self.activityIndicator.startAnimating()
            #if DEBUG
            self.accessibilityIdentifier = "ComposerAttachmentCellTableViewCell.\(size)_uploading"
            #endif
        } else {
            self.activityIndicator.stopAnimating()
            #if DEBUG
            self.accessibilityIdentifier = "ComposerAttachmentCellTableViewCell.\(size)"
            #endif
        }
    }

    @IBAction private func clickDeleteButton(_ sender: Any) {
        self.delegate?.clickDeleteButton(for: self.objectID)
    }

}
