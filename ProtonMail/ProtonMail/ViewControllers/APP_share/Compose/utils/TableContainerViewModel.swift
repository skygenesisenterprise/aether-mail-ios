//
//  EmbeddingViewModel.swift
//  Proton Mail - Created on 11/04/2019.
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

class TableContainerViewModel: NSObject {
    private var latestErrorBanner: BannerView?

    var numberOfSections: Int {
        fatalError()
    }

    func numberOfRows(in section: Int) -> Int {
        fatalError()
    }
}

extension TableContainerViewModel: BannerRequester {
    internal func errorBannerToPresent() -> BannerView? {
        return self.latestErrorBanner
    }
}

@objc protocol BannerPresenting {
    @objc func presentBanner(_ sender: BannerRequester)
}
@objc protocol BannerRequester {
    @objc func errorBannerToPresent() -> BannerView?
}
