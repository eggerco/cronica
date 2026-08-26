//
//  SiriNavigationBridge.swift
//  Cronica
//

import Foundation
import CronicaCore

enum SiriNavigationBridge {
    private static let pendingDeepLinkKey = "siri.pendingDeepLink"
    private static let openSearchKey = "siri.openSearch"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WidgetAppGroup.identifier)
    }

    @MainActor
    static func storePendingDeepLink(_ url: URL) {
        defaults?.set(url.absoluteString, forKey: pendingDeepLinkKey)
    }

    @MainActor
    static func consumePendingDeepLink() -> URL? {
        guard let raw = defaults?.string(forKey: pendingDeepLinkKey),
              let url = URL(string: raw)
        else { return nil }
        defaults?.removeObject(forKey: pendingDeepLinkKey)
        return url
    }

    @MainActor
    static func requestOpenSearch() {
        defaults?.set(true, forKey: openSearchKey)
    }

    @MainActor
    static func consumeOpenSearchRequest() -> Bool {
        guard defaults?.bool(forKey: openSearchKey) == true else { return false }
        defaults?.removeObject(forKey: openSearchKey)
        return true
    }
}
