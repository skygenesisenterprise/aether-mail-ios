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

import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import UIKit
import VCard

struct ContactDecryptionResult {
    let decryptedText: String?
    let signKey: ArmoredKey?
    let decryptError: Bool
}

protocol ContactParserResultDelegate: AnyObject {
    func append(emails: [ContactEditEmail])
    func append(addresses: [ContactEditAddress])
    func append(telephones: [ContactEditPhone])
    func append(informations: [ContactEditInformation])
    func append(fields: [ContactEditField])
    func append(notes: [ContactEditNote])
    func append(urls: [ContactEditUrl])
    func append(structuredName: ContactEditStructuredName)

    func update(verifyType3: Bool)
    func update(decryptionError: Bool)
    func update(profilePicture: UIImage?)
}

protocol ContactParserProtocol {
    func parsePlainTextContact(
        data: String,
        contextProvider: CoreDataContextProviderProtocol,
        contactID: ContactID
    )
    func parseEncryptedOnlyContact(
        card: CardData,
        passphrase: Passphrase,
        userKeys: [ArmoredKey]
    ) throws
    func parseSignAndEncryptContact(
        card: CardData,
        passphrase: Passphrase,
        firstUserKey: ArmoredKey?,
        userKeys: [ArmoredKey]
    ) throws
    func verifySignature(
        signature: ArmoredSignature,
        plainText: String,
        userKeys: [ArmoredKey],
        passphrase: Passphrase
    ) -> Bool
}

final class ContactParser: ContactParserProtocol {
    private enum ParserError: Error {
        case decryptionFailed
        case userKeyNotProvided
    }

    private weak var resultDelegate: ContactParserResultDelegate?

    init(resultDelegate: ContactParserResultDelegate) {
        self.resultDelegate = resultDelegate
    }

    func parsePlainTextContact(
        data: String,
        contextProvider: CoreDataContextProviderProtocol,
        contactID: ContactID
    ) {
        guard let vCard = PMNIEzvcard.parseFirst(data) else { return }

        let emails = vCard.getEmails()
        var order = 1
        var contactEmails: [ContactEditEmail] = []
        for email in emails {
            let types = email.getTypes()
            let typeRaw = types.isEmpty ? "" : (types.first ?? "")
            let type = ContactFieldType.get(raw: typeRaw)

            let object = ContactEditEmail(
                order: order,
                type: type == .empty ? .email : type,
                email: email.getValue(),
                isNew: false,
                keys: nil,
                contactID: contactID.rawValue,
                encrypt: nil,
                sign: nil,
                scheme: nil,
                mimeType: nil,
                delegate: nil,
                contextProvider: contextProvider
            )
            contactEmails.append(object)
            order += 1
        }
        self.resultDelegate?.append(emails: contactEmails)
    }

    func parseEncryptedOnlyContact(
        card: CardData,
        passphrase: Passphrase,
        userKeys: [ArmoredKey]
    ) throws {
        let decryptionResult = self.decryptMessage(
            encryptedText: card.data,
            passphrase: passphrase,
            userKeys: userKeys
        )
        self.resultDelegate?.update(decryptionError: decryptionResult.decryptError)
        guard let decryptedText = decryptionResult.decryptedText else {
            throw ParserError.decryptionFailed
        }
        try self.parseDecryptedContact(data: decryptedText)
    }

    func parseSignAndEncryptContact(
        card: CardData,
        passphrase: Passphrase,
        firstUserKey: ArmoredKey?,
        userKeys: [ArmoredKey]
    ) throws {
        guard let firstUserKey = firstUserKey else {
            throw ParserError.userKeyNotProvided
        }

        let decryptionResult = self.decryptMessage(
            encryptedText: card.data,
            passphrase: passphrase,
            userKeys: userKeys
        )
        self.resultDelegate?.update(decryptionError: decryptionResult.decryptError)
        let key = decryptionResult.signKey ?? firstUserKey
        guard let decryptedText = decryptionResult.decryptedText else {
            throw ParserError.decryptionFailed
        }

        let verifyType3 = self.verifyDetached(
            signature: ArmoredSignature(value: card.signature),
            plainText: decryptedText,
            key: key
        )
        self.resultDelegate?.update(verifyType3: verifyType3)

        try self.parseDecryptedContact(data: decryptedText)
    }

    func verifySignature(
        signature: ArmoredSignature,
        plainText: String,
        userKeys: [ArmoredKey],
        passphrase: Passphrase
    ) -> Bool {
        var isVerified = false
        for key in userKeys {
            do {
                isVerified = try Sign.verifyDetached(
                    signature: signature,
                    plainText: plainText,
                    verifierKey: key,
                    verifyTime: CryptoGo.CryptoGetUnixTime()
                )

                guard isVerified else { continue }
                if !key.value.check(passphrase: passphrase) {
                    isVerified = false
                }
                return isVerified
            } catch {
                isVerified = false
            }
        }
        // Should be false
        return isVerified
    }
}

// MARK: Decrypted contact

// Private functions
extension ContactParser {
    enum VCardTypes: String {
        case telephone = "Telephone"
        case address = "Address"
        case organization = "Organization"
        case title = "Title"
        case nickname = "Nickname"
        case birthday = "Birthday"
        case anniversary = "Anniversary"
        case gender = "Gender"
        case url = "Url"
        case photo = "Photo"
        case structuredName = "StructuredName"
    }

    private func verifyDetached(
        signature: ArmoredSignature,
        plainText: String,
        key: ArmoredKey
    ) -> Bool {
        do {
            return try Sign.verifyDetached(
                signature: signature,
                plainText: plainText,
                verifierKey: key,
                verifyTime: CryptoGo.CryptoGetUnixTime()
            )
        } catch {
            return false
        }
    }

    private func decryptMessage(
        encryptedText: String,
        passphrase: Passphrase,
        userKeys: [ArmoredKey]
    ) -> ContactDecryptionResult {
        var decryptedText: String?
        var signKey: ArmoredKey?
        var decryptError = false
        for key in userKeys {
            do {
                decryptedText = try encryptedText.decryptMessageWithSingleKeyNonOptional(key, passphrase: passphrase)
                signKey = key
                decryptError = false
                break
            } catch {
                decryptError = true
            }
        }
        return ContactDecryptionResult(
            decryptedText: decryptedText,
            signKey: signKey,
            decryptError: decryptError
        )
    }

    private func parseDecryptedContact(data: String) throws {
        try ObjC.catchException { [weak self] in
            guard let self = self,
                  let vCard = PMNIEzvcard.parseFirst(data) else { return }
            self.parse(types: vCard.getPropertyTypes(), vCard: vCard)
            self.parse(customs: vCard.getCustoms())
            self.parse(notes: vCard.getNotes())
            self.parse(structuredName: vCard.getStructuredName())
        }
    }

    private func parse(types: [String], vCard: PMNIVCard) {
        types
            .compactMap { VCardTypes(rawValue: $0) }
            .forEach { vCardType in
                switch vCardType {
                case .telephone:
                    self.parse(telephones: vCard.getTelephoneNumbers())
                case .address:
                    self.parse(addresses: vCard.getAddresses())
                case .organization:
                    vCard.getOrganizations().forEach { self.parse(organization: $0) }
                case .title:
                    vCard.getTitles().forEach { self.parse(title: $0) }
                case .nickname:
                    vCard.getNicknames().forEach { self.parse(nickName: $0) }
                case .birthday:
                    self.parse(birthdays: vCard.getBirthdays())
                case .gender:
                    self.parse(gender: vCard.getGender())
                case .url:
                    self.parse(urls: vCard.getUrls())
                case .photo:
                    self.parse(photo: vCard.getPhoto())
                case .structuredName:
                    self.parse(structuredName: vCard.getStructuredName())
                case .anniversary:
                    self.parse(anniversary: vCard.getAnniversary())
                }
            }
    }

    private func parse(telephones: [PMNITelephone]) {
        var order = 1
        var contactTelephones: [ContactEditPhone] = []
        for phone in telephones {
            let types = phone.getTypes()
            let typeRaw = types.isEmpty ? "" : (types.first ?? "")
            let type = ContactFieldType.get(raw: typeRaw)
            let contactEditPhone = ContactEditPhone(
                order: order,
                type: type == .empty ? .phone : type,
                phone: phone.getText(),
                isNew: false
            )
            contactTelephones.append(contactEditPhone)
            order += 1
        }
        self.resultDelegate?.append(telephones: contactTelephones)
    }

    private func parse(addresses: [PMNIAddress]) {
        var order = 1
        var results: [ContactEditAddress] = []
        for address in addresses {
            let types = address.getTypes()
            let typeRaw = types.isEmpty ? "" : (types.first ?? "")
            let type = ContactFieldType.get(raw: typeRaw)

            let pobox = address.getPoBoxes()
                .asCommaSeparatedList(trailingSpace: false)
            let street = address.getStreetAddress()
            let extended = address.getExtendedAddress()
            let locality = address.getLocality()
            let region = address.getRegion()
            let postal = address.getPostalCode()
            let country = address.getCountry()

            let contactEditAddress = ContactEditAddress(
                order: order,
                type: type == .empty ? .address : type,
                pobox: pobox,
                street: street,
                streetTwo: extended,
                locality: locality,
                region: region,
                postal: postal,
                country: country,
                isNew: false
            )
            results.append(contactEditAddress)
            order += 1
        }
        self.resultDelegate?.append(addresses: results)
    }

    private func parse(organization: PMNIOrganization?) {
        let contactEditInformation = ContactEditInformation(
            type: .organization,
            value: organization?.getValue() ?? "",
            isNew: false
        )
        self.resultDelegate?.append(informations: [contactEditInformation])
    }

    private func parse(title: PMNITitle?) {
        let info = ContactEditInformation(
            type: .title,
            value: title?.getTitle() ?? "",
            isNew: false
        )
        self.resultDelegate?.append(informations: [info])
    }

    private func parse(nickName: PMNINickname?) {
        let contactEditInformation = ContactEditInformation(
            type: .nickname,
            value: nickName?.getNickname() ?? "",
            isNew: false
        )
        self.resultDelegate?.append(informations: [contactEditInformation])
    }

    private func parse(birthdays: [PMNIBirthday]) {
        let contactEditInformations = birthdays.map { birthday in
            ContactEditInformation(
                type: .birthday,
                value: birthday.formattedBirthday,
                isNew: false
            )
        }
        self.resultDelegate?.append(informations: contactEditInformations)
    }

    private func parse(gender: PMNIGender?) {
        guard let gender = gender else { return }
        let contactEditInformation = ContactEditInformation(
            type: .gender,
            value: gender.getGender(),
            isNew: false
        )
        self.resultDelegate?.append(informations: [contactEditInformation])
    }

    private func parse(anniversary: PMNIAnniversary?) {
        guard let anniversary = anniversary else { return }
        let contactEditInformation = ContactEditInformation(
            type: .anniversary,
            value: anniversary.getDate(),
            isNew: false
        )
        resultDelegate?.append(informations: [contactEditInformation])
    }

    private func parse(urls: [PMNIUrl]) {
        var order = 1
        var results: [ContactEditUrl] = []
        for url in urls {
            let typeRaw = url.getType()
            let type = ContactFieldType.get(raw: typeRaw)
            let contactEditUrl = ContactEditUrl(
                order: order,
                type: type == .empty ? .url : type,
                url: url.getValue(),
                isNew: false
            )
            results.append(contactEditUrl)
            order += 1
        }
        self.resultDelegate?.append(urls: results)
    }

    private func parse(photo: PMNIPhoto?) {
        guard let photo = photo else { return }
        let rawData = photo.getRawData()
        self.resultDelegate?.update(profilePicture: UIImage(data: rawData))
    }

    private func parse(customs: [PMNIPMCustom]) {
        var order = 1
        var results: [ContactEditField] = []
        for custom in customs {
            let typeRaw = custom.getType()
            let type = ContactFieldType.get(raw: typeRaw)
            let contactEditField = ContactEditField(
                order: order,
                type: type,
                field: custom.getValue(),
                isNew: false
            )
            results.append(contactEditField)
            order += 1
        }
        self.resultDelegate?.append(fields: results)
    }

    private func parse(notes: [PMNINote]) {
        guard !notes.isEmpty else { return }
        let notesToAdd = notes.map { ContactEditNote(note: $0.getNote(), isNew: false) }
        self.resultDelegate?.append(notes: notesToAdd)
    }

    private func parse(structuredName: PMNIStructuredName?) {
        guard let structuredName = structuredName else { return }
        let contactEditStructuredName = ContactEditStructuredName(
            firstName: structuredName.getGiven(),
            lastName: structuredName.getFamily(),
            isCreatingContact: false
        )
        resultDelegate?.append(structuredName: contactEditStructuredName)
    }
}
