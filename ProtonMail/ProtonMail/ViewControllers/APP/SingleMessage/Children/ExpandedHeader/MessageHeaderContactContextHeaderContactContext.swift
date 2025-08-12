//
//  MessageHeaderContactContext.swift
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
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

enum MessageHeaderContactContext {
    case eventParticipant(emailAddress: String)
    case recipient(ContactVO)
    case sender(Sender)

    var contact: ContactVO {
        switch self {
        case .eventParticipant(let emailAddress):
            return ContactVO(name: emailAddress, email: emailAddress)
        case .recipient(let contactVO):
            return contactVO
        case .sender(let sender):
            return ContactVO(name: sender.name, email: sender.address)
        }
    }
}
