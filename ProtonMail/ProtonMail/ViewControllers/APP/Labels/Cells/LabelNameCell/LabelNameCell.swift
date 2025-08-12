//
//  LabelNameCell .swift
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
import UIKit

protocol LabelNameDelegate: AnyObject {
    func nameChanged(name: String)
}

final class LabelNameCell: UITableViewCell, AccessibleCell {

    @IBOutlet private var nameField: LabelTextField!
    private weak var delegate: LabelNameDelegate?
    private let maximum: Int = 100

    override func awakeFromNib() {
        super.awakeFromNib()
        self.nameField.delegate = self
        self.nameField.backgroundColor = .clear
        self.contentView.backgroundColor = ColorProvider.BackgroundNorm
    }

    func config(name: String, type: PMLabelType, delegate: LabelNameDelegate?) {
        nameField.set(text: name, preferredFont: .title2)
        self.delegate = delegate

        let labelPlaceHolder = LocalString._labels_label_name_text
        let folderPlaceHolder = LocalString._labels_folder_name_text
        self.nameField.placeholder = type == .folder ? folderPlaceHolder : labelPlaceHolder
        generateCellAccessibilityIdentifiers(labelPlaceHolder)
    }
}

extension LabelNameCell: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard var text = textField.text,
              let textRange = Range(range, in: text) else {
            return false
        }

        text.replaceSubrange(textRange, with: string)
        if text.count <= self.maximum {
            self.delegate?.nameChanged(name: text)
            return true
        }
        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
