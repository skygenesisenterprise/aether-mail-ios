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

import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import ProtonCoreLog

typealias FetchVerificationKeysUseCase = UseCase<FetchVerificationKeys.Output, FetchVerificationKeys.Params>

final class FetchVerificationKeys: FetchVerificationKeysUseCase {
    typealias Output = (pinnedKeys: [ArmoredKey], keysResponse: KeysResponse?)

    private let dependencies: Dependencies
    private let userAddresses: [Address]

    init(dependencies: Dependencies, userAddresses: [Address]) {
        self.dependencies = dependencies
        self.userAddresses = userAddresses
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        if let userAddress = userAddresses.first(where: { $0.email == params.email }) {
            let validKeys = nonCompromisedUserAddressKeys(belongingTo: userAddress)
            callback(.success((validKeys, nil)))
        } else {
            fecthPreContactAndKeyResponse(for: params.email) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let tuple):
                    guard let preContact = tuple.preContact else {
                        callback(.success(([], tuple.keysResponse)))
                        return
                    }
                    let output = self.getPinnedKeys(contact: preContact, keysResponse: tuple.keysResponse)
                    callback(.success(output))

                case .failure(let error):
                    callback(.failure(error))
                }
            }
        }
    }

    private func nonCompromisedUserAddressKeys(belongingTo address: Address) -> [ArmoredKey] {
        address.keys
            .filter { $0.flags.contains(.notCompromised) }
            .map { ArmoredKey(value: $0.publicKey) }
    }

    private func fecthPreContactAndKeyResponse(
        for email: String,
        completion: @escaping (Result<(preContact: PreContact?, keysResponse: KeysResponse), Error>) -> Void
    ) {
        var preContact: PreContact?
        fetchVerifiedContact(email: email) { [weak self] result in
            preContact = result
            self?.fetchPublicKeys(email: email) { result in
                switch result {
                case .success(let keyResponse):
                    let value = (preContact, keyResponse)
                    completion(.success(value))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    private func fetchVerifiedContact(email: String, completion: @escaping (PreContact?) -> Void) {
        dependencies.fetchAndVerifyContacts.execute(params: .init(emailAddresses: [email])) { result in
            let preContact = (try? result.get())?.first
            completion(preContact)
        }
    }

    private func fetchPublicKeys(email: String, completion: @escaping (Result<KeysResponse, Error>) -> Void) {
        ConcurrencyUtils.runWithCompletion(
            block: dependencies.fetchEmailsPublicKeys.execute,
            argument: email,
            callCompletionOn: executionQueue,
            completion: completion
        )
    }

    private func getPinnedKeys(contact: PreContact, keysResponse: KeysResponse) -> Output {
        let pinnedKeys = contact.pgpKeys
        let apiKeys = keysResponse.keys

        let compromisedKeyFingerprints = apiKeys
            .filter { !$0.flags.contains(.notCompromised) }
            .map(\.publicKey.fingerprint)

        let validKeys: [ArmoredKey] = pinnedKeys
            .filter { pinnedKey in
                var error: NSError?
                guard let pinnedCryptoKey = CryptoGo.CryptoNewKey(pinnedKey, &error) else {
                    if let error = error {
                        PMLog.error(error)
                    }
                    return false
                }

                let pinnedKeyFingerprint = pinnedCryptoKey.getFingerprint()
                return !compromisedKeyFingerprints.contains(pinnedKeyFingerprint)
            }
            .compactMap { UnArmoredKey(value: $0) }
            .compactMap { try? $0.armor() }

        return (validKeys, keysResponse)
    }
}

extension FetchVerificationKeys {

    struct Params {
        let email: String
    }
}

extension FetchVerificationKeys {
    struct Dependencies {
        let fetchAndVerifyContacts: FetchAndVerifyContactsUseCase
        let fetchEmailsPublicKeys: FetchEmailAddressesPublicKeyUseCase
    }
}
