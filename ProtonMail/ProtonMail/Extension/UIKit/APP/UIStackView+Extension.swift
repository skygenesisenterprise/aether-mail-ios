//
//  UIStackView+Extension.swift
//  Proton Mail - Created on 2018/10/11.
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

extension UIStackView {
    static func stackView(axis: NSLayoutConstraint.Axis = .horizontal,
                          distribution: Distribution = .fill,
                          alignment: Alignment = .fill,
                          spacing: CGFloat = 0) -> UIStackView {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = axis
        stackView.distribution = distribution
        stackView.alignment = alignment
        stackView.spacing = spacing
        return stackView
    }

    func clearAllViews() {
        arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
    }
}
