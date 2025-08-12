// Copyright (c) 2021 Proton AG
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

import PromiseKit
import ProtonCoreAPIClient
import ProtonCoreCrypto
import ProtonCoreServices

/// Encrypt outside address builder
class EOAddressBuilder: PackageBuilder {
    let password: Passphrase
    let passwordHint: String?
    let session: Data
    let algo: Algorithm

    /// prepared attachment list
    let preAttachments: [PreAttachment]
    let apiService: APIService

    init(type: PGPScheme,
         email: String,
         sendPreferences: SendPreferences,
         session: Data,
         algo: Algorithm,
         password: Passphrase,
         atts: [PreAttachment],
         passwordHint: String?,
         apiService: APIService) {
        self.session = session
        self.algo = algo
        self.password = password
        self.preAttachments = atts
        self.passwordHint = passwordHint
        self.apiService = apiService
        super.init(type: type, email: email, sendPreferences: sendPreferences)
    }

    override func build() -> Promise<AddressPackageBase> {
        return async {
            let encodedKeyPackage = try self.session
                .getSymmetricPacket(withPwd: self.password.value, algo: self.algo.value)?
                .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            // create outside encrypt packet
            let token = String.randomString(32) as String
            let based64Token = token.encodeBase64() as String
            let encryptedToken = try based64Token.encryptNonOptional(password: self.password.value)

            // start build auth package
            let authModuls: AuthModulusResponse = try `await`(
                self.apiService.run(route: AuthAPI.Router.modulus)
            )
            guard let modulsId = authModuls.modulusID else {
                throw UpdatePasswordError.invalidModulusID.error
            }
            guard let newModuls = authModuls.modulus else {
                throw UpdatePasswordError.invalidModulus.error
            }

            // generat new verifier
            let newSaltForLoginPwd: Data = try Crypto.random(byte: 10) // for the login password needs to set 80 bits

            guard let auth = try SrpAuthForVerifier(self.password, newModuls, newSaltForLoginPwd) else {
                throw UpdatePasswordError.cantHashPassword.error
            }

            let verifier = try auth.generateVerifier(2_048)
            let authPacket = PasswordAuth(modulus_id: modulsId,
                                          salt: newSaltForLoginPwd.encodeBase64(),
                                          verifer: verifier.encodeBase64())

            var attPack: [AttachmentPackage] = []
            for att in self.preAttachments {
                let newKeyPack = try att.session.getSymmetricPacket(withPwd: self.password.value, algo: att.algo.value)?
                    .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let attPacket = AttachmentPackage(attachmentID: att.attachmentId, attachmentKey: newKeyPack)
                attPack.append(attPacket)
            }

            let package = EOAddressPackage(token: based64Token,
                                           encToken: encryptedToken,
                                           auth: authPacket,
                                           passwordHint: self.passwordHint,
                                           email: self.email,
                                           bodyKeyPacket: encodedKeyPackage,
                                           plainText: self.sendPreferences.mimeType == .plainText,
                                           attachmentPackages: attPack,
                                           scheme: self.sendType)
            return package
        }
    }
}
