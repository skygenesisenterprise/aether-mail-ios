//
//  Analytics.swift
//  Proton Mail - Created on 30/11/2018.
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
import ProtonMailAnalytics
import UIKit

class Analytics {
    static var shared = Analytics()

    enum Environment: String {
        case production
    }

    private(set) var isEnabled = false

    private static var sentryEndpoint: String {
        return "https://cb78ae0c2ede43539c8ea95653847634@mail-api.proton.me/core/v4/reports/sentry/13"
    }

    private let analytics: ProtonMailAnalyticsProtocol

    init(analytics: ProtonMailAnalyticsProtocol = ProtonMailAnalytics(endPoint: Analytics.sentryEndpoint)) {
        self.analytics = analytics
    }

    func setup(environment: Environment, reportCrashes: Bool, telemetry: Bool) {
        isEnabled = telemetry
        analytics.setup(
            environment: environment.rawValue,
            debug: false,
            reportCrashes: reportCrashes,
            telemetry: telemetry
        )
    }

    func assignUser(userID: UserID?) {
        analytics.assignUser(userID: userID?.rawValue)
    }

    func sendEvent(_ event: MailAnalyticsEvent, trace: String? = nil) {
        guard isEnabled else { return }
        analytics.track(event: event, trace: trace)
    }

    func sendError(_ error: MailAnalyticsErrorEvent, trace: String? = nil, fingerprint: Bool = false) {
        guard isEnabled else { return }
        analytics.track(error: error, trace: trace, fingerprint: fingerprint)
    }
}
