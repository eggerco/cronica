//
//  KeychainHelper.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 22/04/23.
//

import Foundation
import Security

final class KeychainHelper {
    static let standard = KeychainHelper()
    private init() { }

    @discardableResult
    func save(_ data: Data, service: String, account: String) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as [CFString: Any] as CFDictionary

        SecItemDelete(query)

        let attributes = query.merging([
            kSecValueData: data
        ] as [CFString: Any]) { _, new in new } as CFDictionary

        let status = SecItemAdd(attributes, nil)
        return status == errSecSuccess
    }

    func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as [CFString: Any] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    func delete(service: String, account: String) -> Bool {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
        ] as [CFString: Any] as CFDictionary

        return SecItemDelete(query) == errSecSuccess
    }
}
