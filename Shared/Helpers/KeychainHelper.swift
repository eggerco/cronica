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
    
    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as [CFString : Any] as CFDictionary

        let status = SecItemAdd(query, nil)

        if status == errSecDuplicateItem {
            let searchQuery = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ] as [CFString : Any] as CFDictionary

            let attributesToUpdate = [
                kSecValueData: data
            ] as [CFString : Any] as CFDictionary

            SecItemUpdate(searchQuery, attributesToUpdate)
        }
    }
    
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as [CFString : Any] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        return (result as? Data)
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
        ] as [CFString : Any] as CFDictionary
        
        // Delete item from keychain
        SecItemDelete(query)
    }
}
