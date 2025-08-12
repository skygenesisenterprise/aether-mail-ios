//
//  BannerViewModel.swift
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

enum SpamType {
    case dmarcFailed
    case autoPhishing
}

extension SpamType {

    var text: NSAttributedString {
        let style = FontManager.CaptionInverted
        switch self {
        case .autoPhishing:
            return LocalString._auto_phising_banner_message.apply(style: style)
        case .dmarcFailed:
            let message = LocalString._dmarc_failed_banner_message.apply(style: style)
            let learnMore = LocalString._learn_more.apply(style: linkAttributes)
            return message + .init(string: " ") + learnMore
        }
    }

    var icon: UIImage {
        switch self {
        case .autoPhishing:
            return IconProvider.hook
        case .dmarcFailed:
            return IconProvider.fire
        }
    }

    var buttonTitle: NSAttributedString? {
        guard case .autoPhishing = self else { return nil }
        return LocalString._auto_phising_banner_button_title.apply(style: FontManager.body2RegularInverted)
    }

    private var linkAttributes: [NSAttributedString.Key: Any] {
        var style = FontManager.CaptionInverted
        style[.link] = Link.dmarcFailedInfo
        style[.underlineStyle] = NSUnderlineStyle.single.rawValue
        style[.underlineColor] = ColorProvider.TextInverted as UIColor
        style[.font] = UIFont.preferredFont(for: .footnote, weight: .regular)
        return style
    }
}
