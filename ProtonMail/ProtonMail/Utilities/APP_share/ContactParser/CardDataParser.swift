// Copyright (c) 2022 Proton AG
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

import VCard
import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import ProtonCoreLog

#if !APP_EXTENSION
import LifetimeTracker
#endif

class CardDataParser {
    private let userKeys: [ArmoredKey]

    init(userKeys: [ArmoredKey]) {
        self.userKeys = userKeys

#if !APP_EXTENSION
        trackLifetime()
#endif
    }

    // swiftlint:disable:next function_body_length
    func verifyAndParseContact(with email: String, from cards: [CardData]) -> PreContact? {
        for card in cards {
            switch card.type {
            case .SignedOnly:
                guard self.verifySignature(of: card) else {
                    continue
                }

                if let vcard = PMNIEzvcard.parseFirst(card.data) {
                    let emails = vcard.getEmails()
                    for vcardEmail in emails where email == vcardEmail.getValue() {
                        let group = vcardEmail.getGroup()
                        let encrypt = vcard.getPMEncrypt(group)
                        let keys = vcard.getKeys(group)
                        let isEncrypt = encrypt?.getValue() ?? "false" == "true" ? true : false
                        let schemeType = vcard.getPMScheme(group)
                        let mimeType = vcard.getPMMimeType(group)?.getValue()

                        let sign = vcard.getPMSign(group)
                        let signStatus: PreContact.SignStatus
                        if sign?.getValue() == "true" {
                            signStatus = .sign
                        } else if sign?.getValue() == "false" {
                            signStatus = .doNotSign
                        } else {
                            signStatus = .signingFlagNotFound
                        }

                        var pubKeys: [Data] = []
                        for key in keys {
                            let keyGroup = key.getGroup()
                            if keyGroup == group {
                                let value = key.getBinary() // based 64 key
                                if let cryptoKey = CryptoGo.CryptoKey(value), !cryptoKey.isExpired() {
                                    pubKeys.append(value)
                                }
                            }
                        }
                        let preContact = PreContact(
                            email: email,
                            pubKeys: pubKeys,
                            sign: signStatus,
                            encrypt: isEncrypt,
                            scheme: schemeType?.getValue(),
                            mimeType: mimeType
                        )
                        return preContact
                    }
                }
            default:
                // see https://confluence.protontech.ch/display/MAILFE/Contact+vCard
                // for the explanation why we only look for .SignedOnly
                break
            }
        }
        return nil
    }

    private func verifySignature(of cardData: CardData) -> Bool {
        do {
            return try Sign.verifyDetached(
                signature: ArmoredSignature(value: cardData.signature),
                plainText: cardData.data,
                verifierKeys: userKeys,
                verifyTime: CryptoGo.CryptoGetUnixTime()
            )
        } catch {
            PMLog.error(error)
            return false
        }
    }
}

#if !APP_EXTENSION
extension CardDataParser: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
#endif
