// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreNetworking

final class MessageDetailRequest: Request {
    let messageID: MessageID
    let priority: APIPriority?

    var path: String {
        "/\(Constants.App.API_PREFIXED)/messages/\(messageID.rawValue)"
    }

    var header: [String: Any] {
        var header: [String: Any] = [:]
        if let priority = priority {
            header["priority"] = priority.rawValue
        }
        return header
    }

    init(messageID: MessageID, priority: APIPriority? = nil) {
        self.messageID = messageID
        self.priority = priority
    }
}
