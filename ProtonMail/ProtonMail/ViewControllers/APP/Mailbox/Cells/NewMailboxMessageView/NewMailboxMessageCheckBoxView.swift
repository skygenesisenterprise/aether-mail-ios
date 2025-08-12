//
//  NewMailboxMessageCheckBoxView.swift
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

class NewMailboxMessageCheckBoxView: UIView {

    let tickImageView = SubviewsFactory.tickImageVIew

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
        setUpSelf()
    }

    private func addSubviews() {
        addSubview(tickImageView)
    }

    private func setUpLayout() {
        tickImageView.translatesAutoresizingMaskIntoConstraints = false
        [
            tickImageView.topAnchor.constraint(equalTo: topAnchor),
            tickImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tickImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tickImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
            .activate()
    }

    private func setUpSelf() {
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = ColorProvider.InteractionNorm
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var tickImageVIew: UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.isUserInteractionEnabled = false
        return imageView
    }

}
