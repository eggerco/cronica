//
//  SimklKnownItemsStore.swift
//  Cronica
//

import Foundation

/// Tracks contentIDs last seen on SIMKL so removal diffs don't flag Cronica-only titles.
enum SimklKnownItemsStore {
    private static let key = "simklKnownContentIDs"

    static func all() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    static func insert(_ contentID: String) {
        var set = all()
        set.insert(contentID)
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    static func replace(with contentIDs: Set<String>) {
        UserDefaults.standard.set(Array(contentIDs), forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
