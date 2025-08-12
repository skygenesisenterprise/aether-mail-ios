// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCoreCryptoGoInterface

struct SendPreferences: Equatable {
    // TODO: can `CryptoKey` be made `Equatable` again?
    static func == (lhs: SendPreferences, rhs: SendPreferences) -> Bool {
        lhs.encrypt == rhs.encrypt &&
        lhs.sign == rhs.sign &&
        lhs.pgpScheme == rhs.pgpScheme &&
        lhs.mimeType == rhs.mimeType &&
        lhs.publicKey?.getFingerprint() == rhs.publicKey?.getFingerprint() &&
        lhs.isPublicKeyPinned == rhs.isPublicKeyPinned &&
        lhs.hasApiKeys == rhs.hasApiKeys &&
        lhs.error == rhs.error
    }

    let encrypt: Bool
    let sign: Bool
    let pgpScheme: PGPScheme
    let mimeType: SendMIMEType
    let publicKey: CryptoKey?
    let isPublicKeyPinned: Bool
    let hasApiKeys: Bool
    let error: EncryptionPreferencesError?
}
