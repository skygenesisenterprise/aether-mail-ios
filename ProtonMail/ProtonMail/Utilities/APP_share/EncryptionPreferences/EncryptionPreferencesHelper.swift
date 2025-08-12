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
import ProtonCoreDataModel

// swiftlint:disable:next type_body_length
enum EncryptionPreferencesHelper {
    static func getEncryptionPreferences(email: String,
                                         keysResponse: KeysResponse,
                                         userDefaultSign: Bool,
                                         userAddresses: [Address],
                                         contact: PreContact?) -> EncryptionPreferences {
        let selfAddress = userAddresses.first(where: { $0.email == email && $0.send == .active })

        var selfSendConfig: SelfSendConfig?
        let apiKeysConfig: APIKeysConfig
        let pinnedKeysConfig: PinnedKeysConfig
        if let selfAddress = selfAddress {
            let publicKey = selfAddress.keys.first?.publicKey
            let key = convertToCryptoKey(from: publicKey)
            selfSendConfig = SelfSendConfig(address: selfAddress, publicKey: key)
            // For own addresses, we use the decrypted keys in selfSend and do not fetch any data from the API
            apiKeysConfig = APIKeysConfig(publicKeys: [], recipientType: .internal)
            pinnedKeysConfig = PinnedKeysConfig(encrypt: false,
                                                sign: .signingFlagNotFound,
                                                scheme: nil,
                                                mimeType: nil,
                                                pinnedKeys: [])
        } else {
            let apiKeys: [PublicKeyWithAPIData] = keysResponse.keys.compactMap { keyResponse in
                var error: NSError?
                if let key = CryptoGo.CryptoNewKey(keyResponse.publicKey.unArmor, &error) {
                    return error != nil ? nil : PublicKeyWithAPIData(apiData: keyResponse, cryptoKey: key)
                }
                return nil
            }

            apiKeysConfig = APIKeysConfig(publicKeys: apiKeys, recipientType: keysResponse.recipientType)

            let rawContactKeys: [Data] = contact?.pgpKeys ?? []
            let keys: [CryptoKey] = rawContactKeys.compactMap { rawKey in
                var error: NSError?
                let key = CryptoGo.CryptoNewKey(rawKey, &error)
                return error != nil ? nil : key
            }
            pinnedKeysConfig = PinnedKeysConfig(encrypt: contact?.encrypt ?? false,
                                                sign: contact?.sign ?? .signingFlagNotFound,
                                                scheme: contact?.scheme,
                                                mimeType: contact?.mimeType,
                                                pinnedKeys: keys)
        }

        let contactPublicKeyModel = getContactPublicKeyModel(email: email,
                                                             apiKeysConfig: apiKeysConfig,
                                                             pinnedKeysConfig: pinnedKeysConfig)
        return extractEncryptionPreferences(model: contactPublicKeyModel,
                                            defaultSign: userDefaultSign,
                                            selfSend: selfSendConfig)
    }

    /**
     * Extract the encryption preferences from a public-key model corresponding to a certain email address
     */
    static func extractEncryptionPreferences(model: ContactPublicKeyModel,
                                             defaultSign: Bool,
                                             selfSend: SelfSendConfig?) -> EncryptionPreferences {
        // Determine encrypt and sign flags, plus PGP scheme and MIME type.
        // Take mail settings into account if they are present
        var sign = model.sign
        if sign == .signingFlagNotFound {
            if defaultSign {
                sign = .sign
            } else {
                sign = .doNotSign
            }
        }

        let newModel = ContactPublicKeyModel(encrypt: model.encrypt,
                                             sign: sign,
                                             scheme: model.scheme,
                                             mimeType: model.mimeType,
                                             email: model.email,
                                             publicKeys: model.publicKeys,
                                             trustedFingerprints: model.trustedFingerprints,
                                             encryptionCapableFingerprints: model.encryptionCapableFingerprints,
                                             verifyOnlyFingerprints: model.verifyOnlyFingerprints,
                                             isPGPInternal: model.isPGPInternal,
                                             isPGPExternalWithWDKKeys: model.isPGPExternalWithWDKKeys)

        if let selfSend = selfSend { // case of own address
            return generateEncryptionPrefFromOwnAddress(selfSendConfig: selfSend, publicKeyModel: newModel)
        } else if model.isPGPInternal { // case of internal user
            return generateEncryptionPrefInternal(publicKeyModel: newModel)
        } else if model.isPGPExternalWithWDKKeys { // case of external user with WKD keys
            return generateEncryptionPrefExternalWithWDKKeys(publicKeyModel: newModel)
        } else { // case of external user without WKD keys
            return generateEncryptionPrefExternalWithoutWKDKeys(publicKeyModel: newModel)
        }
    }

    static func generateEncryptionPrefFromOwnAddress(selfSendConfig: SelfSendConfig,
                                                     publicKeyModel: ContactPublicKeyModel) -> EncryptionPreferences {
        let hasApiKeys = !selfSendConfig.address.keys.isEmpty
        let canAddressSend = selfSendConfig.address.send == .active
        var error: EncryptionPreferencesError?

        if !canAddressSend {
            error = .internalUserDisable
        } else if !hasApiKeys {
            error = .internalUserNoApiKey
        } else if selfSendConfig.publicKey == nil {
            error = .internalUserNoValidApiKey
        }

        return .init(encrypt: true,
                     sign: true,
                     scheme: publicKeyModel.scheme,
                     mimeType: publicKeyModel.mimeType,
                     isInternal: true,
                     hasApiKeys: publicKeyModel.hasApiKeys,
                     sendKey: error == nil ? selfSendConfig.publicKey : nil,
                     isSendKeyPinned: false,
                     error: error)
    }

    static func generateEncryptionPrefInternal(publicKeyModel: ContactPublicKeyModel) -> EncryptionPreferences {
        if !publicKeyModel.hasApiKeys {
            return encryptionPrefInternal(publicKeyModel: publicKeyModel,
                                          sendKey: nil,
                                          isSendKeyPinned: false,
                                          error: .internalUserNoApiKey)
        }

        if publicKeyModel.validApiSendKey == nil {
            return encryptionPrefInternal(publicKeyModel: publicKeyModel,
                                          sendKey: nil,
                                          isSendKeyPinned: false,
                                          error: .internalUserNoValidApiKey)
        }
        if !publicKeyModel.hasPinnedKeys {
            // API keys are ordered in terms of user preference.
            // The primary key (first in the list) will be used for sending
            return encryptionPrefInternal(publicKeyModel: publicKeyModel,
                                          sendKey: publicKeyModel.primaryApiKey,
                                          isSendKeyPinned: false,
                                          error: nil)
        }
        // if there are pinned keys, make sure the primary API key is trusted and valid for sending
        let sendKey = publicKeyModel.pinnedKeys
            .first(where: { $0.getFingerprint() == publicKeyModel.primaryApiKeyFingerprint })
        if !publicKeyModel.isPrimaryApiKeyTrustedAndValid || sendKey == nil {
            return encryptionPrefInternal(publicKeyModel: publicKeyModel,
                                          sendKey: publicKeyModel.validApiSendKey,
                                          isSendKeyPinned: false,
                                          error: .primaryNotPinned)
        }
        return encryptionPrefInternal(publicKeyModel: publicKeyModel,
                                      sendKey: sendKey,
                                      isSendKeyPinned: true,
                                      error: nil)
    }

    static func generateEncryptionPrefExternalWithWDKKeys(
        publicKeyModel: ContactPublicKeyModel
    ) -> EncryptionPreferences {
        if publicKeyModel.validApiSendKey == nil {
            return encryptionPrefExternalWithWDKKeys(publicKeyModel: publicKeyModel,
                                                     sendKey: nil,
                                                     isSendKeyPinned: false,
                                                     error: .userNoValidWKDKey)
        }
        if !publicKeyModel.hasPinnedKeys {
            // WKD keys are ordered in terms of user preference.
            // The primary key (first in the list) will be used for sending
            return encryptionPrefExternalWithWDKKeys(publicKeyModel: publicKeyModel,
                                                     sendKey: publicKeyModel.primaryApiKey,
                                                     isSendKeyPinned: false,
                                                     error: nil)
        }
        // if there are pinned keys, make sure the primary API key is trusted and valid for sending
        let isPrimaryTrustedAndValid = publicKeyModel.isPrimaryApiKeyTrustedAndValid
        let sendKey = publicKeyModel.pinnedKeys
            .first(where: { $0.getFingerprint() == publicKeyModel.primaryApiKeyFingerprint })
        if !isPrimaryTrustedAndValid || sendKey == nil {
            return encryptionPrefExternalWithWDKKeys(publicKeyModel: publicKeyModel,
                                                     sendKey: publicKeyModel.validApiSendKey,
                                                     isSendKeyPinned: false,
                                                     error: .primaryNotPinned)
        }
        return encryptionPrefExternalWithWDKKeys(publicKeyModel: publicKeyModel,
                                                 sendKey: sendKey,
                                                 isSendKeyPinned: true,
                                                 error: nil)
    }

    static func generateEncryptionPrefExternalWithoutWKDKeys(
        publicKeyModel: ContactPublicKeyModel
    ) -> EncryptionPreferences {
        if !publicKeyModel.hasPinnedKeys {
            return encryptionPrefExternalWithoutWKDKeys(publicKeyModel: publicKeyModel,
                                                        sendKey: nil,
                                                        isSendKeyPinned: false,
                                                        error: nil)
        }
        // Pinned keys are ordered in terms of preference. Make sure the first is valid
        if !publicKeyModel.isValidForSending(fingerprint: publicKeyModel.primaryPinnedKeyFingerprint) {
            return encryptionPrefExternalWithoutWKDKeys(publicKeyModel: publicKeyModel,
                                                        sendKey: nil,
                                                        isSendKeyPinned: false,
                                                        error: .externalUserNoValidPinnedKey)
        }
        return encryptionPrefExternalWithoutWKDKeys(publicKeyModel: publicKeyModel,
                                                    sendKey: publicKeyModel.primaryPinnedKey,
                                                    isSendKeyPinned: true,
                                                    error: nil)
    }

    /**
     * For a given email address and its corresponding public keys (retrieved from the API
     * and/or the corresponding contact),
     * construct the contact public key model, which reflects the content of the contact.
     */
    static func getContactPublicKeyModel(email: String,
                                         apiKeysConfig: APIKeysConfig,
                                         pinnedKeysConfig: PinnedKeysConfig) -> ContactPublicKeyModel {
        var trustedFingerprints: Set<String> = []
        var encryptionCapableFingerprints: Set<String> = []
        let isInternal = apiKeysConfig.recipientType == .internal

        // keys from contact
        pinnedKeysConfig.pinnedKeys.forEach { key in
            let fingerprint = key.getFingerprint()
            trustedFingerprints.insert(fingerprint)
            if key.canEncrypt() {
                encryptionCapableFingerprints.insert(fingerprint)
            }
        }

        let sortedPinnedKeys = sortPinnedKeys(keys: pinnedKeysConfig.pinnedKeys,
                                              encryptionCapableFingerprints: encryptionCapableFingerprints)

        // keys from API
        var verifyOnlyFingerprints: Set<String> = []
        let apiKeys = apiKeysConfig.publicKeys
        apiKeys.forEach { key in
            if !key.cryptoKey.isExpired() {
                let fingerprint = key.cryptoKey.getFingerprint()
                if getKeyVerificationOnlyStatus(key: key) {
                    verifyOnlyFingerprints.insert(fingerprint)
                }
                if key.cryptoKey.canEncrypt() {
                    encryptionCapableFingerprints.insert(fingerprint)
                }
            }
        }

        let sortedApiKeys = sortedApiKeys(keys: apiKeysConfig.publicKeys,
                                          trustedFingerprints: trustedFingerprints,
                                          verifyOnlyFingerprints: verifyOnlyFingerprints)

        return .init(encrypt: pinnedKeysConfig.encrypt,
                     sign: pinnedKeysConfig.sign,
                     scheme: pinnedKeysConfig.scheme,
                     mimeType: pinnedKeysConfig.mimeType,
                     email: email,
                     publicKeys: ContactPublicKeys(apiKeys: sortedApiKeys,
                                                   pinnedKeys: sortedPinnedKeys),
                     trustedFingerprints: trustedFingerprints,
                     encryptionCapableFingerprints: encryptionCapableFingerprints,
                     verifyOnlyFingerprints: verifyOnlyFingerprints,
                     isPGPInternal: isInternal,
                     isPGPExternalWithWDKKeys: !isInternal && !apiKeys.isEmpty)
    }

    /**
     * Given a public key retrieved from the API, return true if it has been marked as invalid for encryption,
     * and it is thus verification-only.
     * Return false if it's marked valid for encryption. Return undefined otherwise
     */
    static func getKeyVerificationOnlyStatus(key: PublicKeyWithAPIData) -> Bool {
        !key.apiData.flags.contains(.notObsolete)
    }

    /**
     * Sort list of pinned keys retrieved from the API. Keys that can be used for sending take preference
     */
    static func sortPinnedKeys(keys: [CryptoKey],
                               encryptionCapableFingerprints: Set<String>) -> [CryptoKey] {
        let encryptionEnableKeys = keys.filter { encryptionCapableFingerprints.contains($0.getFingerprint()) }
        let otherKeys = keys.filter { !encryptionCapableFingerprints.contains($0.getFingerprint()) }
        return encryptionEnableKeys + otherKeys
    }

    /**
     * Sort list of keys retrieved from the API. Trusted keys take preference.
     * For two keys such that both are either trusted or not, non-verify-only keys take preference
     */
    static func sortedApiKeys(keys: [PublicKeyWithAPIData],
                              trustedFingerprints: Set<String>,
                              verifyOnlyFingerprints: Set<String>) -> [CryptoKey] {
        keys.map(\.cryptoKey).sorted { lhs, rhs in
            let lhsFingerprint = lhs.getFingerprint()
            let rhsFingerprint = rhs.getFingerprint()

            if trustedFingerprints.contains(lhsFingerprint), trustedFingerprints.contains(rhsFingerprint) {
                return verifyOnlyFingerprints.contains(lhsFingerprint)
            }

            return trustedFingerprints.contains(lhsFingerprint)
        }
    }

    static func convertToCryptoKey(from rawKey: String?) -> CryptoKey? {
        var error: NSError?
        guard let key = CryptoGo.CryptoNewKey(rawKey?.unArmor, &error),
              error == nil else {
            return nil
        }
        return key
    }

    private static func encryptionPrefInternal(
        publicKeyModel: ContactPublicKeyModel,
        sendKey: CryptoKey?,
        isSendKeyPinned: Bool,
        error: EncryptionPreferencesError?
    ) -> EncryptionPreferences {
        return .init(
            encrypt: true,
            sign: true,
            scheme: publicKeyModel.scheme,
            mimeType: publicKeyModel.mimeType,
            isInternal: true,
            hasApiKeys: !publicKeyModel.publicKeys.apiKeys.isEmpty,
            sendKey: sendKey,
            isSendKeyPinned: isSendKeyPinned,
            error: error
        )
    }

    private static func encryptionPrefExternalWithWDKKeys(
        publicKeyModel: ContactPublicKeyModel,
        sendKey: CryptoKey?,
        isSendKeyPinned: Bool,
        error: EncryptionPreferencesError?
    ) -> EncryptionPreferences {
        return .init(encrypt: true,
                     sign: true,
                     scheme: publicKeyModel.scheme,
                     mimeType: publicKeyModel.mimeType,
                     isInternal: false,
                     hasApiKeys: true,
                     sendKey: sendKey,
                     isSendKeyPinned: isSendKeyPinned,
                     error: error)
    }

    private static func encryptionPrefExternalWithoutWKDKeys(
        publicKeyModel: ContactPublicKeyModel,
        sendKey: CryptoKey?,
        isSendKeyPinned: Bool,
        error: EncryptionPreferencesError?
    ) -> EncryptionPreferences {
        let sign: Bool
        switch publicKeyModel.sign {
        case .sign:
            sign = true
        case .doNotSign, .signingFlagNotFound:
            sign = false
        }
        return .init(
            encrypt: publicKeyModel.encrypt,
            sign: sign,
            scheme: publicKeyModel.scheme,
            mimeType: publicKeyModel.mimeType,
            isInternal: false,
            hasApiKeys: false,
            sendKey: sendKey,
            isSendKeyPinned: isSendKeyPinned,
            error: error
        )
    }
}
