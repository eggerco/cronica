//
//  WatchStatistics.swift
//  Cronica
//

import Foundation

/// Local-only watch statistics derived from Core Data Watchlist items.
struct WatchStatistics: Equatable {
    var watchedCount: Int
    var estimatedMinutes: Int
    var watchedLast7Days: Int
    var watchedLast30Days: Int

    var estimatedHoursText: String {
        let hours = Double(estimatedMinutes) / 60.0
        if hours < 1 {
            return String(format: String(localized: "%d min"), estimatedMinutes)
        }
        return String(format: String(localized: "%.1f hours"), hours)
    }

    static func compute(from items: [WatchlistItem], now: Date = Date()) -> WatchStatistics {
        let calendar = Calendar.current
        let start7 = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let start30 = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        var watchedCount = 0
        var estimatedMinutes = 0
        var last7 = 0
        var last30 = 0

        for item in items where item.isWatched {
            watchedCount += 1
            if let date = item.watchedDate {
                if date >= start7 { last7 += 1 }
                if date >= start30 { last30 += 1 }
            }

            let runtime = Int(item.runtimeMinutes)
            guard runtime > 0 else { continue }

            if item.isMovie {
                estimatedMinutes += runtime
            } else if item.isTvShow {
                let episodes = item.watchedEpisodeCount
                guard episodes > 0 else { continue }
                estimatedMinutes += episodes * runtime
            }
        }

        return WatchStatistics(
            watchedCount: watchedCount,
            estimatedMinutes: estimatedMinutes,
            watchedLast7Days: last7,
            watchedLast30Days: last30
        )
    }
}
