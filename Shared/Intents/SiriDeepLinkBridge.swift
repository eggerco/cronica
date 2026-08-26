//
//  SiriDeepLinkBridge.swift
//  Cronica
//

import Foundation
import CronicaCore

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
enum SiriDeepLinkBridge {
    private static let pendingKey = "siri.pendingDeepLink"

    @MainActor
    static func storePending(_ url: URL) {
        UserDefaults(suiteName: WidgetAppGroup.identifier)?.set(url.absoluteString, forKey: pendingKey)
    }

    @MainActor
    static func consumePending() -> URL? {
        guard let defaults = UserDefaults(suiteName: WidgetAppGroup.identifier),
              let raw = defaults.string(forKey: pendingKey),
              let url = URL(string: raw)
        else { return nil }
        defaults.removeObject(forKey: pendingKey)
        return url
    }
}
#endif
