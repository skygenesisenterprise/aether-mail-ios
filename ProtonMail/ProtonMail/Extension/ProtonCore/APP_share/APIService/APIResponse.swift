//
//  APIServiceResponse.swift
//  Proton Mail - Created on 6/18/15.
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

enum HTTPStatusCode: Int {
    case ok = 200
    case badRequest = 400
    case notFound = 404
    case internalServerError = 500
    case badGateway = 502
}

extension HTTPStatusCode {
    static func != (lhs: Int, rhs: HTTPStatusCode) -> Bool {
        lhs != rhs.rawValue
    }
}
