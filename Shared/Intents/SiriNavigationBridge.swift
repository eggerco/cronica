//
//  SiriNavigationBridge.swift
//  Cronica
//

import Foundation
import CronicaCore

enum PendingAppNavigation: String {
    case search
    case watchlist
    case upNext
    case markUpNextEpisode
}

enum SiriNavigationBridge {
    private static let pendingDeepLinkKey = "siri.pendingDeepLink"
    private static let openSearchKey = "siri.openSearch"
    private static let pendingNavigationKey = "app.pendingNavigation"

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
    static func storePendingNavigation(_ action: PendingAppNavigation) {
        defaults?.set(action.rawValue, forKey: pendingNavigationKey)
    }

    @MainActor
    static func publishPendingNavigation(_ action: PendingAppNavigation) {
        storePendingNavigation(action)
#if os(iOS)
        QuickActionCoordinator.shared.stage(action)
#endif
    }

    @MainActor
    static func peekPendingNavigation() -> PendingAppNavigation? {
        guard let raw = defaults?.string(forKey: pendingNavigationKey) else { return nil }
        return PendingAppNavigation(rawValue: raw)
    }

    @MainActor
    static func consumePendingNavigation() -> PendingAppNavigation? {
        guard let action = peekPendingNavigation() else { return nil }
        defaults?.removeObject(forKey: pendingNavigationKey)
        return action
    }

    @MainActor
    static func requestOpenSearch() {
        publishPendingNavigation(.search)
        defaults?.set(true, forKey: openSearchKey)
    }

    @MainActor
    static func consumeOpenSearchRequest() -> Bool {
        if peekPendingNavigation() == .search {
            _ = consumePendingNavigation()
            defaults?.removeObject(forKey: openSearchKey)
            return true
        }
        guard defaults?.bool(forKey: openSearchKey) == true else { return false }
        defaults?.removeObject(forKey: openSearchKey)
        return true
    }
}
