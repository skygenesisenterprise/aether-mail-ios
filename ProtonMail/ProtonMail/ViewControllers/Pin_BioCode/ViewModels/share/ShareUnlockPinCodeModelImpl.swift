//
//  ShareUnlockPinCodeModelImpl.swift
//  Proton Mail - Created on 7/26/17.
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

class ShareUnlockPinCodeModelImpl: PinCodeViewModel {
    typealias Dependencies = HasPinCodeVerifier & HasUserDefaults

    var currentStep: PinCodeStep = .enterPin

    var enterPin: String = ""

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func cancel() -> String {
        return LocalString._general_confirm_action
    }

    override func setCode (_ code: String) -> PinCodeStep {
        switch currentStep {
        case .enterPin:
            enterPin = code
            currentStep = .done
        case .reEnterPin, .done:
            break
        default:
            enterPin = ""
            currentStep = .enterPin
        }

        return currentStep
    }

    override func verifyPinCode() async -> Bool {
        currentStep = .enterPin
        return await dependencies.pinCodeVerifier.isVerified(pinCode: enterPin)
    }

    override func getPinFailedRemainingCount() -> Int {
        return max(10 - dependencies.userDefaults[.pinFailedCount], 0)
    }

    override func getPinFailedError() -> String {
        let c = 10 - dependencies.userDefaults[.pinFailedCount]
        if c < 4 {
            let error = String.localizedStringWithFormat(LocalString._attempt_remaining_until_secure_data_wipe, c)
            return error
        }
        let text = String.localizedStringWithFormat(LocalString._attempt_remaining, c)
        return "\(LocalString._incorrect_pin) \(text)"
    }

    override func checkTouchID() -> Bool {
        return true
    }

    override func done(completion: @escaping (Bool) -> Void) {
        completion(false)
    }
}
