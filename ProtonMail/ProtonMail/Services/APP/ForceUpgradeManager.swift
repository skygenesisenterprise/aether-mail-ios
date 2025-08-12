//
//  ForceUpgradeManager.swift
//  Proton Mail
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
import LifetimeTracker
import ProtonCoreForceUpgrade
import ProtonCoreNetworking
#if DEBUG
import OHHTTPStubs
import OHHTTPStubsSwift
#endif

class ForceUpgradeManager: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
    static let shared = ForceUpgradeManager()

    private init() {
        trackLifetime()
    }

    var forceUpgradeHelper: ForceUpgradeDelegate = {
        return ForceUpgradeHelper(config: .mobile(.AppStore.mail))
    }()
}

#if DEBUG
extension ForceUpgradeManager {

    func setupUITestsMocks() {
        HTTPStubs.setEnabled(true)
        stub(condition: isHost("proton.me") && isPath("/payments/status") && isMethodGET()) { _ in
            let body = Data(self.responseString5003.utf8)
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }
    }

    var responseString5003: String {
        """
        {
            "Code": 5003,
            "Error": "Test error description",
            "ErrorDescription": ""
        }
        """
    }
}
#endif
