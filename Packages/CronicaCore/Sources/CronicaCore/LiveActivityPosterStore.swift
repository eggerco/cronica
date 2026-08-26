//
//  LiveActivityPosterStore.swift
//  CronicaCore
//

import Foundation

/// Shared poster bytes for Live Activities via App Group UserDefaults.
/// Avoids ActivityKit's ~4KB attributes budget (Data is base64-encoded there).
public enum LiveActivityPosterStore {
    private static let keyPrefix = "liveActivity.poster."

    public static func save(_ data: Data, contentID: String) {
        defaults?.set(data, forKey: key(for: contentID))
    }

    public static func load(contentID: String) -> Data? {
        defaults?.data(forKey: key(for: contentID))
    }

    public static func remove(contentID: String) {
        defaults?.removeObject(forKey: key(for: contentID))
    }

    public static func removeAll() {
        guard let defaults else { return }
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(keyPrefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WidgetAppGroup.identifier)
    }

    private static func key(for contentID: String) -> String {
        keyPrefix + contentID
    }
}
