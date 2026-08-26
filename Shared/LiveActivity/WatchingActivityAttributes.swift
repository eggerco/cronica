//
//  WatchingActivityAttributes.swift
//  Cronica
//

import Foundation
#if os(iOS)
import ActivityKit
#endif

#if os(iOS)
struct WatchingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var elapsedMinutes: Int
        var remainingMinutes: Int
        var progress: Double
    }

    /// Poster lives in App Group UserDefaults (`LiveActivityPosterStore`), not here —
    /// ActivityKit's ~4KB budget can't reliably hold JPEG Data (base64 inflation).
    var contentID: String
    var totalMinutes: Int
    var startedAt: Date
}
#endif

enum WatchingActivityDeepLink {
    static func url(for contentID: String) -> URL? {
        URL(string: "cronica://\(contentID)")
    }
}
