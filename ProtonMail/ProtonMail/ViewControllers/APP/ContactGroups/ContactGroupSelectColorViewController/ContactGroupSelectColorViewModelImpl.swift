//
//  ContactGroupSelectColorViewModelImpl.swift
//  Proton Mail - Created on 2018/8/23.
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

import Foundation

class ContactGroupSelectColorViewModelImpl: ContactGroupSelectColorViewModel {
    let originalColor: String
    var currentColor: String
    let colors = ColorManager.forLabel
    let refreshHandler: (String) -> Void

    var havingUnsavedChanges: Bool {
        return originalColor != currentColor
    }

    init(currentColor: String, refreshHandler: @escaping (String) -> Void) {
        self.originalColor = currentColor
        self.currentColor = currentColor
        self.refreshHandler = refreshHandler
    }

    func isSelectedColor(at indexPath: IndexPath) -> Bool {
        guard indexPath.row < colors.count else {
            return false
        }

        return colors[indexPath.row] == currentColor
    }

    func getCurrentColorIndex() -> Int {
        for (i, color) in colors.enumerated() {
            if color == currentColor {
                return i
            }
        }

        // This should not happen
        currentColor = ColorManager.defaultColor
        return 0
    }

    func updateCurrentColor(to indexPath: IndexPath) {
        guard indexPath.row < colors.count else {
            currentColor = ColorManager.getRandomColor()
            return
        }

        currentColor = colors[indexPath.row]
    }

    func getTotalColors() -> Int {
        return colors.count
    }

    func getColor(at indexPath: IndexPath) -> String {
        guard indexPath.row < colors.count else {
            return ColorManager.defaultColor
        }

        return colors[indexPath.row]
    }

    func save() {
        refreshHandler(currentColor)
    }
}
