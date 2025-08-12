// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

@testable import ProtonMail
import UIKit

class UndoActionHandlerBaseMock: UIViewController, UndoActionHandlerBase {
    var undoActionManager: ProtonMail.UndoActionManagerProtocol?

    var isShowUndoActionCalled = false
    var undoTokens = [String]()
    var bannerMessage: String?
    var delaySendSeconds: Int = 0

    var composerPresentingVC: UIViewController? { self }

    func showUndoAction(undoTokens: [String], title: String) {
        isShowUndoActionCalled = true
        self.undoTokens = undoTokens
        self.bannerMessage = title
    }
}
