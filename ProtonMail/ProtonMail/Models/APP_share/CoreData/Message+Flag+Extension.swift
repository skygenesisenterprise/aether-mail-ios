//
//  Message+Flag+Extension.swift
//  Proton Mail - Created on 11/5/18.
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

extension Message {

    // periphery:ignore:all
    struct Flag: OptionSet {
        let rawValue: Int64

        /// whether a message is received
        static let received    = Flag(rawValue: 1 << 0 ) // const FLAG_RECEIVED = 1; //this it TYPE:INBOXS
        /// whether a message is sent
        static let sent        = Flag(rawValue: 1 << 1 ) // const FLAG_SENT = 2; //this is TYPE:SENT
        /// whether the message is between Proton Mail recipients
        static let `internal`  = Flag(rawValue: 1 << 2 ) // const FLAG_INTERNAL = 4;
        /// whether the message is end-to-end encrypted
        static let e2e         = Flag(rawValue: 1 << 3 ) // const FLAG_E2E = 8;

        /// whether the message is an autoresponse
        static let auto        = Flag(rawValue: 1 << 4 ) // const FLAG_AUTO = 16;
        /// whether the message is replied to
        static let replied     = Flag(rawValue: 1 << 5 ) // const FLAG_REPLIED = 32;
        /// whether the message is replied all to
        static let repliedAll  = Flag(rawValue: 1 << 6 ) // const FLAG_REPLIEDALL = 64;
        /// whether the message is forwarded
        static let forwarded   = Flag(rawValue: 1 << 7 ) // const FLAG_FORWARDED = 128;

        /// whether the message has been responded to with an autoresponse
        static let autoReplied = Flag(rawValue: 1 << 8 ) // const FLAG_AUTOREPLIED = 256;
        /// whether the message is an import
        static let imported    = Flag(rawValue: 1 << 9 ) // const FLAG_IMPORTED = 512;
        /// whether the message has ever been opened by the user
        static let opened      = Flag(rawValue: 1 << 10) // const FLAG_OPENED = 1024;
        /// whether a read receipt has been sent in response to the message
        static let receiptSent = Flag(rawValue: 1 << 11) // const FLAG_RECEIPT_SENT = 2048;

        /// Mark -- For drafts only
        /// whether to request a read receipt for the message
        static let receiptRequest = Flag(rawValue: 1 << 16) // const RECEIPT_REQUEST = 65536
        /// whether to attach the public key
        static let publicKey = Flag(rawValue: 1 << 17) // const PUBLIC_KEY = 131072
        /// whether to sign the message
        static let sign = Flag(rawValue: 1 << 18) // const SIGN = 262144

        static let unsubscribed = Flag(rawValue: 1 << 19) // 524288
        static let scheduledSend = Flag(rawValue: 1 << 20)

        static let dmarcPass = Flag(rawValue: 1 << 23)
        // Incoming mail failed dmarc authentication.
        static let dmarcFailed = Flag(rawValue: 1 << 26)

        // The message is in spam and the user moves it to a new location that is not spam or trash (e.g. inbox or archive).
        static let hamManual = Flag(rawValue: 1 << 27)

        // Incoming mail is marked as phishing by anti-spam filters.
        static let autoPhishing = Flag(rawValue: 1 << 30)

        // If the expiration time (when applicable), is frozen or not.
        // Frozen means that it's a self destructing message
        // Not frozen means that it's an auto-deleting message
        static let isExpirationTimeFrozen = Flag(rawValue: 1 << 32)

        // If the snoozed message passed the snooze time, the BE will pop the message and set this flag.
        // Once the message is read, the flag will be removed.
        static let showReminder = Flag(rawValue: 1 << 34)
    }

    var flag: Flag {
        get {
            return Flag(rawValue: self.flags.int64Value)
        }
        set {
            self.flags = NSNumber(value: newValue.rawValue)
        }
    }
}
