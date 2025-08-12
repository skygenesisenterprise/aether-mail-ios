//
//  LabelAsActionSheetViewModel.swift
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

protocol LabelAsActionSheetViewModel {
    var menuLabels: [MenuLabel] { get }
    var initialLabelSelectionStatus: [MenuLabel: PMActionSheetItem.MarkType] { get }
}

struct LabelAsActionSheetViewModelMessages: LabelAsActionSheetViewModel {
    let menuLabels: [MenuLabel]
    private var initialLabelSelectionCount: [MenuLabel: Int] = [:]
    private(set) var initialLabelSelectionStatus: [MenuLabel: PMActionSheetItem.MarkType] = [:]

    init(menuLabels: [MenuLabel], messages: [MessageEntity]) {
        self.menuLabels = menuLabels
        menuLabels.forEach { initialLabelSelectionCount[$0] = 0 }
        initialLabelSelectionCount.forEach { (label, _) in
            for msg in messages where msg.contains(location: label.location) {
                if let labelCount = initialLabelSelectionCount[label] {
                    initialLabelSelectionCount[label] = labelCount + 1
                } else {
                    initialLabelSelectionCount[label] = 1
                }
            }
        }

        initialLabelSelectionCount.forEach { (key, value) in
            if value == messages.count {
                initialLabelSelectionStatus[key] = .checkMark
            } else if value < messages.count && value > 0 {
                initialLabelSelectionStatus[key] = .dash
            } else {
                initialLabelSelectionStatus[key] = PMActionSheetItem.MarkType.none
            }
        }
    }
}

struct LabelAsActionSheetViewModelConversations: LabelAsActionSheetViewModel {
    let menuLabels: [MenuLabel]
    private var initialLabelSelectionCount: [MenuLabel: Int] = [:]
    private(set) var initialLabelSelectionStatus: [MenuLabel: PMActionSheetItem.MarkType] = [:]

    init(menuLabels: [MenuLabel], conversations: [ConversationEntity]) {
        self.menuLabels = menuLabels
        menuLabels.forEach { initialLabelSelectionCount[$0] = 0 }
        initialLabelSelectionCount.forEach { (label, _) in
            for conv in conversations where conv.getLabelIDs().contains(label.location.labelID) {
                if let labelCount = initialLabelSelectionCount[label] {
                    initialLabelSelectionCount[label] = labelCount + 1
                } else {
                    initialLabelSelectionCount[label] = 1
                }
            }
        }

        initialLabelSelectionCount.forEach { (key, value) in
            if value == conversations.count {
                initialLabelSelectionStatus[key] = .checkMark
            } else if value < conversations.count && value > 0 {
                initialLabelSelectionStatus[key] = .dash
            } else {
                initialLabelSelectionStatus[key] = PMActionSheetItem.MarkType.none
            }
        }
    }
}

struct LabelAsActionSheetViewModelConversationMessages: LabelAsActionSheetViewModel {
    let menuLabels: [MenuLabel]
    private var initialLabelSelectionCount: [MenuLabel: Int] = [:]
    private(set) var initialLabelSelectionStatus: [MenuLabel: PMActionSheetItem.MarkType] = [:]

    init(menuLabels: [MenuLabel], conversationMessages: [MessageEntity]) {
        self.menuLabels = menuLabels
        menuLabels.forEach { initialLabelSelectionCount[$0] = 0 }
        initialLabelSelectionCount.forEach { (label, _) in
            for message in conversationMessages where message.getLabelIDs().contains(label.location.labelID) {
                if let labelCount = initialLabelSelectionCount[label] {
                    initialLabelSelectionCount[label] = labelCount + 1
                } else {
                    initialLabelSelectionCount[label] = 1
                }
            }
        }

        initialLabelSelectionCount.forEach { (key, value) in
            if value == conversationMessages.count {
                initialLabelSelectionStatus[key] = .checkMark
            } else if value < conversationMessages.count && value > 0 {
                initialLabelSelectionStatus[key] = .dash
            } else {
                initialLabelSelectionStatus[key] = PMActionSheetItem.MarkType.none
            }
        }
    }
}
