//
//  TMDBSessionStore.swift
//  Cronica
//

import Foundation
import Security

enum TMDBSessionStore {
    private static let service = "dev.alexandremadeira.Story.tmdb"
    private static let sessionAccount = "session_id"
    private static let accountIDKey = "tmdbAccountID"

    static var hasSession: Bool { loadSessionID() != nil }

    static func saveSessionID(_ sessionID: String) throws {
        guard !sessionID.isEmpty else {
            delete()
            return
        }
        try save(account: sessionAccount, value: sessionID)
    }

    static func loadSessionID() -> String? {
        load(account: sessionAccount)
    }

    static func saveAccountID(_ id: Int) {
        UserDefaults.standard.set(id, forKey: accountIDKey)
    }

    static func loadAccountID() -> Int {
        UserDefaults.standard.integer(forKey: accountIDKey)
    }

    static func delete() {
        delete(account: sessionAccount)
        UserDefaults.standard.removeObject(forKey: accountIDKey)
    }

    private static func save(account: String, value: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw LibraryImportError.message("Failed to store TMDB session (\(status)).")
        }
    }

    private static func load(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
