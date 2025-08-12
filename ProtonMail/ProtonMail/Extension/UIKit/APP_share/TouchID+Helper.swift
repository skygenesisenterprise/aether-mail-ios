//
//  TouchID+Helper.swift
//  Proton Mail - Created on 3/26/18.
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
import LocalAuthentication

enum BiometricType {
    case none
    case touchID
    case faceID
}

extension UIDevice: BiometricStatusProvider {
    var biometricType: BiometricType {
        get {
            let context = LAContext()
            var error: NSError?
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                return .none
            }
            switch context.biometryType {
            case .none:
                return .none
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            default:
                return .touchID // TODO: will iPhones have both TouchID and FaceID some day?
            }
        }
    }
}

// sourcery: mock
protocol BiometricStatusProvider {
    var biometricType: BiometricType { get }
}
