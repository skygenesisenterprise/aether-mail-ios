//
//  HTMLSecureLoader.swift
//  Proton Mail - Created on 06/01/2019.
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
import WebKit

enum DomPurifyConfig {
    case `default`, protonizer, imageCache, composer, raw

    var value: String {
        switch self {
        case .composer:
            let httpScheme = HTTPRequestSecureLoader.ProtonScheme.http.rawValue
            let httpsScheme = HTTPRequestSecureLoader.ProtonScheme.https.rawValue
            let noScheme = HTTPRequestSecureLoader.ProtonScheme.noProtocol.rawValue
            let valueToAdd = "\(httpScheme)|\(httpsScheme)|\(noScheme)|proton-cid"
            return """
            {
            ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|blob|xmpp|data|\(valueToAdd)):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))/i,
            ADD_TAGS: ['base'],
            ADD_ATTR: ['target'],
            FORBID_TAGS: ['input', 'form', 'video', 'audio'],
            FORBID_ATTR: ['srcset'],
            WHOLE_DOCUMENT: true,
            RETURN_DOM: true
            }
            """.replacingOccurrences(of: "\n", with: "")
        case .default:
            let scheme = HTTPRequestSecureLoader.imageCacheScheme
            let httpScheme = HTTPRequestSecureLoader.ProtonScheme.http.rawValue
            let httpsScheme = HTTPRequestSecureLoader.ProtonScheme.https.rawValue
            let noScheme = HTTPRequestSecureLoader.ProtonScheme.noProtocol.rawValue
            let imageScheme = HTTPRequestSecureLoader.ProtonScheme.pmCache.rawValue
            let valueToAdd = "\(httpScheme)|\(httpsScheme)|\(noScheme)|\(scheme)|\(imageScheme)"
            return """
            {
            ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|blob|xmpp|data|\(valueToAdd)):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))/i,
            ADD_TAGS: ['base'],
            ADD_ATTR: ['target'],
            FORBID_TAGS: ['input', 'form', 'video', 'audio'],
            FORBID_ATTR: ['srcset']
            }
            """.replacingOccurrences(of: "\n", with: "")
        case .protonizer:
            return """
            {
            FORBID_TAGS: ['input', 'form'], // Override defaults to allow style (will be processed by juice afterward)
            FORBID_ATTR: {},
            ADD_ATTR: ['target', 'proton-data-src', 'proton-src', 'proton-srcset', 'proton-background', 'proton-poster', 'proton-xlink:href', 'proton-href'],
            WHOLE_DOCUMENT: true,
            RETURN_DOM: true
            }
            """
        case .imageCache:
            let scheme = HTTPRequestSecureLoader.imageCacheScheme
            return """
            {
            ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|blob|xmpp|data|\(scheme)):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))/i,
            WHOLE_DOCUMENT: true,
            RETURN_DOM: true
            }
            """.replacingOccurrences(of: "\n", with: "")
        case .raw:
            // This is used to generate the HTML DOM to display in the webview.
            let scheme = HTTPRequestSecureLoader.imageCacheScheme
            let httpScheme = HTTPRequestSecureLoader.ProtonScheme.http.rawValue
            let httpsScheme = HTTPRequestSecureLoader.ProtonScheme.https.rawValue
            let noScheme = HTTPRequestSecureLoader.ProtonScheme.noProtocol.rawValue
            let imageScheme = HTTPRequestSecureLoader.ProtonScheme.pmCache.rawValue
            let valueToAdd = "\(httpScheme)|\(httpsScheme)|\(noScheme)|\(scheme)|\(imageScheme)"
            return """
            {
            ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|blob|xmpp|data|\(valueToAdd)):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))/i,
            WHOLE_DOCUMENT: true,
            RETURN_DOM: true
            }
            """
        }
    }
}
