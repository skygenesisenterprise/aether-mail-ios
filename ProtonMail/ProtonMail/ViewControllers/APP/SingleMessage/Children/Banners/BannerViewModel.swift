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

import Foundation

final class BannerViewModel {

    let shouldAutoLoadRemoteContent: Bool
    let shouldAutoLoadEmbeddedImage: Bool
    private(set) var expirationTime: Date = .distantFuture
    private var timer: Timer?
    private let unsubscribeActionHandler: UnsubscribeActionHandler
    private let markLegitimateActionHandler: MarkLegitimateActionHandler
    private let receiptActionHandler: ReceiptActionHandler
    private let urlOpener: URLOpener
    let viewMode: ViewMode
    var shouldShowReceiptBanner: Bool {
        guard let message = infoProvider?.message else { return false }
        return message.hasReceiptRequest && !message.isSent
    }
    var hasSentReceipt: Bool {
        infoProvider?.message.hasSentReceipt ?? false
    }

    var recalculateCellHeight: ((_ isLoaded: Bool) -> Void)?
    var resetLoadedHeight: (() -> Void)?
    var updateExpirationTime: ((Int) -> Void)?
    var messageExpired: (() -> Void)?
    var reloadBanners: (() -> Void)?
    var editScheduledMessage: (() -> Void)?
    var unSnoozeMessage: (() -> Void)?

    var canUnsubscribe: Bool {
        guard let message = infoProvider?.message else { return false }
        let unsubscribeMethods = message.unsubscribeMethods
        let isAvailable = unsubscribeMethods?.oneClick != nil || unsubscribeMethods?.httpClient != nil
        return isAvailable && !message.flag.contains(.unsubscribed)
    }

    var isAutoReply: Bool {
        infoProvider?.message.isAutoReply ?? false
    }

    private(set) var infoProvider: MessageInfoProvider? {
        didSet { reloadBanners?() }
    }

    var spamType: SpamType? {
        infoProvider?.message.spam
    }

    var scheduledSendingTime: (String, String)? {
        return infoProvider?.scheduledSendingTime
    }

    var snoozeTime: Date? {
        guard infoProvider?.message.contains(location: .snooze) == true else {
            return nil
        }
        return infoProvider?.message.snoozeTime
    }

    init(
        shouldAutoLoadRemoteContent: Bool,
        expirationTime: Date?,
        shouldAutoLoadEmbeddedImage: Bool,
        unsubscribeActionHandler: UnsubscribeActionHandler,
        markLegitimateActionHandler: MarkLegitimateActionHandler,
        receiptActionHandler: ReceiptActionHandler,
        urlOpener: URLOpener,
        viewMode: ViewMode
    ) {
        self.shouldAutoLoadRemoteContent = shouldAutoLoadRemoteContent
        self.shouldAutoLoadEmbeddedImage = shouldAutoLoadEmbeddedImage
        self.unsubscribeActionHandler = unsubscribeActionHandler
        self.markLegitimateActionHandler = markLegitimateActionHandler
        self.receiptActionHandler = receiptActionHandler
        self.urlOpener = urlOpener
        self.viewMode = viewMode
        setUpTimer(expirationTime: expirationTime)
    }

    deinit {
        timer?.invalidate()
    }

    func setUpTimer(expirationTime: Date?) {
        if let time = expirationTime {
            self.expirationTime = time
            self.timer = Timer.scheduledTimer(
                timeInterval: 1,
                target: self,
                selector: #selector(self.timerUpdate),
                userInfo: nil,
                repeats: true
            )
        }
    }

    func getExpirationOffset() -> Int {
        let referenceDate = Date.getReferenceDate(processInfo: userCachedStatus)
        return Int(self.expirationTime.timeIntervalSince(referenceDate))
    }

    func providerHasChanged(provider: MessageInfoProvider) {
        infoProvider = provider
    }

    @objc
    func unsubscribe() {
        guard let message = infoProvider?.message else { return }
        let unsubscribeMethods = message.unsubscribeMethods
        if unsubscribeMethods?.oneClick != nil {
            unsubscribeActionHandler.oneClickUnsubscribe(messageId: message.messageID)
        } else if let httpClient = unsubscribeMethods?.httpClient {
            open(url: httpClient)
        }
    }

    func markAsLegitimate() {
        guard let message = infoProvider?.message else { return }
        markLegitimateActionHandler.markAsLegitimate(messageId: message.messageID)
    }

    func sendReceipt() {
        guard let message = infoProvider?.message else { return }
        receiptActionHandler.sendReceipt(messageID: message.messageID)
    }

    private func open(url: String) {
        guard let message = infoProvider?.message else { return }
        guard let url = URL(string: url), urlOpener.canOpenURL(url) else { return }
        urlOpener.open(url)
        unsubscribeActionHandler.markAsUnsubscribed(messageId: message.messageID, finish: {})
    }

    @objc
    private func timerUpdate() {
        let offset = getExpirationOffset()
        if offset <= 0 {
            messageExpired?()
        }
        updateExpirationTime?(offset)
    }

    static func calculateExpirationTitle(of offset: Int) -> String {
        let (day, hour, min) = durationsBySecond(seconds: offset + 60)
        if offset <= 0 {
            return LocalString._message_expired
        } else {
            return String(format: LocalString._expires_in_days_hours_mins_seconds, day, hour, min)
        }
    }

    static func durationsBySecond(seconds: Int) -> (days: Int, hours: Int, minutes: Int) {
        return (seconds / (24 * 3_600), (seconds % (24 * 3_600)) / 3_600, seconds % 3_600 / 60)
    }

    func isAutoDeletingMessage() -> Bool {
        infoProvider?.message.isAutoDeleting == true
    }
}
