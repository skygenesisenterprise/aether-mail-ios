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

import Foundation
import class ProtonCoreDataModel.Address
import class ProtonCoreDataModel.UserInfo
import class ProtonCoreNetworking.AuthCredential
import ProtonCoreCrypto

/// Encapsulates the data needed to send a message that is obtained from the CoreData `Message` object
struct MessageSendingData {
    let message: MessageEntity

    /// userInfo information stored with the message object
    let cachedUserInfo: UserInfo?

    /// authCredential information stored with the message object
    let cachedAuthCredential: AuthCredential?

    /// sender email address stored with the message object
    let cachedSenderAddress: Address?

    /// passphrase stored with the message object
    let cachedPassphrase: Passphrase?

    /// default address which status allows for sending a message
    let defaultSenderAddress: Address?
}
