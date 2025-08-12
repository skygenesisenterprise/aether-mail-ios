//
//  AddressAPI.swift
//  Proton Mail - Created on 6/7/16.
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
import ProtonCoreDataModel
import ProtonCoreNetworking

// Addresses API
// Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_addresses.md
struct AddressesAPI {
    /// base message api path
    static let path: String = "/addresses"

    // Create new address [POST /addresses] locked

    // Update address [PUT]
    // static let v_update_address : Int = 3

}

// Responses
final class AddressesResponse: Response {
    var addresses: [Address] = [Address]()
    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        if let addresses = response["Addresses"] as? [[String: Any]] {
            for address in addresses {
                let result = self.parseAddr(res: address)
                guard result else { return false }
            }
            return true
        } else if let address = response["Address"] as? [String: Any] {
            return self.parseAddr(res: address)
        } else {
            return true
        }
    }

    func parseAddr(res: [String: Any]!) -> Bool {
        var keys: [Key] = []
        if let addressKeys = res["Keys"] as? [[String: Any]] {
            for keyRes in addressKeys {
                guard let ID = keyRes["ID"] as? String else { return false }

                keys.append(
                    Key(keyID: ID,
                        privateKey: keyRes["PrivateKey"] as? String,
                        keyFlags: keyRes["Flags"] as? Int ?? 0,
                        token: keyRes["Token"] as? String,
                        signature: keyRes["Signature"] as? String,
                        activation: keyRes["Activation"] as? String,
                        active: keyRes["Active"] as? Int ?? 0,
                        version: keyRes["Version"] as? Int ?? 0,
                        primary: keyRes["Primary"] as? Int ?? 0,
                        isUpdated: false)
                )
            }
        }

        guard let ID = res["ID"] as? String else { return false }

        let sendValue = res["Send"] as? Int ?? 0
        let receiveValue = res["Receive"] as? Int ?? 0
        let statusValue = res["Status"] as? Int ?? 0
        let typeValue = res["Type"] as? Int ?? 0

        let send = Address.AddressSendReceive(rawValue: sendValue) ?? .inactive
        let receive = Address.AddressSendReceive(rawValue: receiveValue) ?? .inactive
        let status = Address.AddressStatus(rawValue: statusValue) ?? .disabled
        let type = Address.AddressType(rawValue: typeValue) ?? .protonDomain

        addresses.append(
            Address(
                addressID: ID,
                domainID: res["DomainID"] as? String,
                email: res["Email"] as? String ?? "",
                send: send,
                receive: receive,
                status: status,
                type: type,
                order: res["Order"] as? Int ?? 0,
                displayName: res["DisplayName"] as? String ?? "",
                signature: res["Signature"] as? String ?? "",
                hasKeys: keys.isEmpty ? 0 : 1,
                keys: keys
            )
        )

        return true
    }
}

// Mark : get addresses
// Get Addresses [GET /addresses]
// Get Address [GET /addresses/{address_id}]
// response : AddressesResponse
struct GetAddressesRequest: Request {
    var path: String {
        return AddressesAPI.path
    }
}

// MARK: update addresses order
// Order Addresses [/addresses/order]
final class UpdateAddressOrder: Request {  // Response

    let newOrder: [String]
    init(adds: [String], authCredential: AuthCredential?) {
        self.newOrder = adds
        self.auth = authCredential
    }

    // custom auth credentical
    let auth: AuthCredential?
    var authCredential: AuthCredential? {
        get {
            return self.auth
        }
    }

    var path: String {
        return AddressesAPI.path + "/order"
    }

    var parameters: [String: Any]? {
        let out: [String: Any] = ["AddressIDs": self.newOrder]
        return out
    }

    var method: HTTPMethod {
        return .put
    }
}

// MARK: update display name

final class UpdateAddressRequest: Request { // Response
    let addressid: String
    let displayName: String
    let signature: String
    init(id: String, displayName: String, signature: String, authCredential: AuthCredential?) {
        self.addressid = id
        self.displayName = displayName
        self.signature = signature
        self.auth = authCredential
    }

    // custom auth credentical
    let auth: AuthCredential?
    var authCredential: AuthCredential? {
        get {
            return self.auth
        }
    }

    var path: String {
        return AddressesAPI.path + "/" + addressid
    }

    var parameters: [String: Any]? {
        let out: [String: Any] = ["DisplayName": displayName,
                                    "Signature": signature]
        return out
    }

    var method: HTTPMethod {
        return .put
    }
}
