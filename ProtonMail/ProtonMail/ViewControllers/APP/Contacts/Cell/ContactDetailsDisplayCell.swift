//
//  ContactDetailsEmailCell.swift
//  Proton Mail - Created on 5/3/17.
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

final class ContactDetailsDisplayCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UILabel!

    func configCell(
        title: String,
        value: String,
        titleStyle: [NSAttributedString.Key : Any] = .DefaultSmall
    ) {
        backgroundColor = ColorProvider.BackgroundNorm
        contentView.backgroundColor = ColorProvider.BackgroundNorm

        self.title.attributedText = title.apply(style: titleStyle)

        let attribute = FontManager.Default.addTruncatingTail()
        self.value.attributedText = value.apply(style: attribute)
    }

}
