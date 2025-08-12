//
//  NonExpandedHeaderViewModel.swift
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

import PromiseKit
import ProtonCoreUIFoundations

class NonExpandedHeaderViewModel: HeaderViewModel {
    enum TrackerDetectionStatus {
        case trackersFound
        case noTrackersFound
        case notDetermined
        case proxyNotEnabled
    }

    var updateTimeLabel: (() -> Void)?

    var shouldShowSentImage: Bool {
        let message = infoProvider.message
        return message.isSent && message.messageLocation != .sent
    }

    var trackerDetectionStatus: TrackerDetectionStatus {
        guard infoProvider.imageProxyEnabled else {
            return .proxyNotEnabled
        }

        guard let trackerProtectionSummary = infoProvider.trackerProtectionSummary else {
            return .notDetermined
        }

        return trackerProtectionSummary.trackers.isEmpty ? .noTrackersFound : .trackersFound
    }

    private var timer: Timer?

    deinit {
        timer?.invalidate()
    }

    func setupTimerIfNeeded() {
        guard infoProvider.message.isScheduledSend else {
            return
        }
        #if DEBUG
        let interval = 1.0
        #else
        let interval = 10.0
        #endif
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateTimeLabel?()
        }
    }
}
