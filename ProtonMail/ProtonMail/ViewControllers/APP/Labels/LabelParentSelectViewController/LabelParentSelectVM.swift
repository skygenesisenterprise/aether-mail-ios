//
//  LabelParentSelectVM.swift
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

import Foundation
import ProtonCoreUIFoundations
import UIKit

protocol LabelParentSelctVMProtocol {
    /// Sorted out data
    var labels: [MenuLabel] { get }
    var parentID: String { get }
    var useFolderColor: Bool { get }

    func selectRow(row: Int)
    func isAllowToSelect(row: Int) -> Bool
    func getFolderColor(label: MenuLabel) -> UIColor
    func finishSelect()
}

protocol LabelParentSelectDelegate: AnyObject {
    func select(parentID: String)
}

final class LabelParentSelectVM: LabelParentSelctVMProtocol {
    let labels: [MenuLabel]
    let name: String
    let useFolderColor: Bool
    private let label: MenuLabel?
    private(set) var parentID: String
    private let originalParentID: String
    private var allowed: [Int: Bool] = [:]
    private let inheritParentColor: Bool
    private weak var delegate: LabelParentSelectDelegate?

    /// - Parameters:
    ///   - labels: Sorted out labels data
    ///   - label: The editing label
    ///   - useFolderColor: use folder color?
    ///   - inheritParentColor: inherit parent color?
    ///   - delegate: delegate
    init(labels: [MenuLabel],
         label: MenuLabel?,
         useFolderColor: Bool,
         inheritParentColor: Bool,
         delegate: LabelParentSelectDelegate?,
         parentID: String) {
        self.labels = labels
        self.label = label
        self.originalParentID = parentID
        self.parentID = parentID
        self.name = label?.name ?? ""
        self.useFolderColor = useFolderColor
        self.inheritParentColor = inheritParentColor
        self.delegate = delegate
    }

    func update(parentID: String) {
        self.parentID = parentID
    }

    /// - Parameter row: Row from tableview, including "None" cell
    func selectRow(row: Int) {
        if row == 0 {
            self.update(parentID: "")
            return
        }
        guard let item = self.labels.getFolderItem(at: row - 1) else {
            return
        }
        self.update(parentID: item.location.rawLabelID)
    }

    /// could this row be selected
    func isAllowToSelect(row: Int) -> Bool {
        if let isAllow = self.allowed[row] {
            return isAllow
        }

        if row == 0 {
            self.allowed[row] = true
            return true
        }

        let realRow = row - 1
        guard let item = self.labels.getFolderItem(at: realRow) else {
            self.allowed[row] = false
            return false
        }

        let targetID = item.location.rawLabelID
        if self.originalParentID == targetID ||
            self.label?.parentID?.rawValue == targetID {
            self.allowed[row] = true
            return true
        }

        if self.label?.location.rawLabelID == targetID {
            self.allowed[row] = false
            return false
        }

        var targetIsChild = false
        if let editLabel = self.label {
            targetIsChild = editLabel.contains(item: item)
        }

        let usedNames = item.subLabels.map { $0.name }
        let hasSameName = usedNames.contains(self.name)

        let newDeepLevel = item.indentationLevel + (label?.deepLevel ?? 1)
        let isAllowDeep = newDeepLevel < 3

        let isAllow = !hasSameName && isAllowDeep && !targetIsChild
        self.allowed[row] = isAllow
        return isAllow
    }

    /// Get folder color, will handle inheritParentColor
    func getFolderColor(label: MenuLabel) -> UIColor {
        guard self.useFolderColor else {
            return ColorProvider.IconNorm
        }

        guard self.inheritParentColor else {
            if let color = label.iconColor {
                return UIColor(hexColorCode: color)
            } else {
                return ColorProvider.IconNorm
            }
        }

        guard let root = self.labels.getRootItem(of: label),
              let rootColor = root.iconColor else {
            if let color = label.iconColor {
                return UIColor(hexColorCode: color)
            } else {
                return ColorProvider.IconNorm
            }
        }
        return UIColor(hexColorCode: rootColor)
    }

    func finishSelect() {
        self.delegate?.select(parentID: self.parentID)
    }
}
