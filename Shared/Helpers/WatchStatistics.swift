//
//  WatchStatistics.swift
//  Cronica
//

import Foundation

struct WatchActivityWeek: Identifiable, Equatable {
    let weekStart: Date
    let count: Int

    var id: Date { weekStart }
    var axisLabel: String { Self.formatWeek(weekStart) }

    fileprivate static func formatWeek(_ date: Date) -> String {
        axisFormatter.string(from: date)
    }

    private static let axisFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()
}

struct WatchHoursWeek: Identifiable, Equatable {
    let weekStart: Date
    let estimatedMinutes: Int

    var id: Date { weekStart }
    var axisLabel: String { WatchActivityWeek.formatWeek(weekStart) }
    var hours: Double { Double(estimatedMinutes) / 60.0 }
}

struct WatchMediaBreakdownSlice: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case movie
        case tvShow
    }

    let kind: Kind
    let count: Int
    let estimatedMinutes: Int

    var id: String { kind.rawValue }

    var label: String {
        switch kind {
        case .movie:
            return String(localized: "Movies")
        case .tvShow:
            return String(localized: "TV Shows")
        }
    }
}

/// Local-only watch statistics derived from Core Data Watchlist items.
struct WatchStatistics: Equatable {
    var watchedCount: Int
    var estimatedMinutes: Int
    var watchedLast7Days: Int
    var watchedLast30Days: Int
    var weeklyActivity: [WatchActivityWeek]
    var weeklyHours: [WatchHoursWeek]
    var mediaBreakdown: [WatchMediaBreakdownSlice]

    var estimatedHoursText: String {
        Self.formatMinutes(estimatedMinutes)
    }

    static func formatMinutes(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        if hours < 1 {
            return String(format: String(localized: "%d min"), minutes)
        }
        return String(format: String(localized: "%.1f hours"), hours)
    }

    static func compute(from items: [WatchlistItem], now: Date = Date(), weekCount: Int = 8) -> WatchStatistics {
        let calendar = Calendar.current
        let start7 = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let start30 = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        var watchedCount = 0
        var totalMinutes = 0
        var last7 = 0
        var last30 = 0

        for item in items where item.isWatched {
            watchedCount += 1
            if let date = activityDate(for: item) {
                if date >= start7 { last7 += 1 }
                if date >= start30 { last30 += 1 }
            }
            totalMinutes += estimatedMinutes(for: item)
        }

        return WatchStatistics(
            watchedCount: watchedCount,
            estimatedMinutes: totalMinutes,
            watchedLast7Days: last7,
            watchedLast30Days: last30,
            weeklyActivity: weeklyActivity(from: items, now: now, weekCount: weekCount, calendar: calendar),
            weeklyHours: weeklyHours(from: items, now: now, weekCount: weekCount, calendar: calendar),
            mediaBreakdown: mediaBreakdown(from: items)
        )
    }

    static func estimatedMinutes(for item: WatchlistItem) -> Int {
        let runtime = Int(item.runtimeMinutes)
        guard runtime > 0 else { return 0 }

        if item.isMovie {
            return runtime
        }
        if item.isTvShow {
            let episodes = item.watchedEpisodeCount
            guard episodes > 0 else { return 0 }
            return episodes * runtime
        }
        return 0
    }

    static func mediaBreakdown(from items: [WatchlistItem]) -> [WatchMediaBreakdownSlice] {
        var movieCount = 0
        var movieMinutes = 0
        var tvCount = 0
        var tvMinutes = 0

        for item in items where item.isWatched {
            let minutes = estimatedMinutes(for: item)
            if item.isMovie {
                movieCount += 1
                movieMinutes += minutes
            } else if item.isTvShow {
                tvCount += 1
                tvMinutes += minutes
            }
        }

        var slices: [WatchMediaBreakdownSlice] = []
        if movieCount > 0 {
            slices.append(WatchMediaBreakdownSlice(kind: .movie, count: movieCount, estimatedMinutes: movieMinutes))
        }
        if tvCount > 0 {
            slices.append(WatchMediaBreakdownSlice(kind: .tvShow, count: tvCount, estimatedMinutes: tvMinutes))
        }
        return slices
    }

    static func weeklyActivity(from items: [WatchlistItem],
                               now: Date,
                               weekCount: Int,
                               calendar: Calendar = .current) -> [WatchActivityWeek] {
        let weekStarts = weekStarts(endingAt: now, count: weekCount, calendar: calendar)
        let knownWeeks = Set(weekStarts)
        var counts = Dictionary(uniqueKeysWithValues: weekStarts.map { ($0, 0) })

        for item in items where item.isWatched {
            guard let weekStart = weekStart(for: activityDate(for: item), in: knownWeeks, calendar: calendar) else { continue }
            counts[weekStart, default: 0] += 1
        }

        return weekStarts.map { WatchActivityWeek(weekStart: $0, count: counts[$0, default: 0]) }
    }

    static func weeklyHours(from items: [WatchlistItem],
                            now: Date,
                            weekCount: Int,
                            calendar: Calendar = .current) -> [WatchHoursWeek] {
        let weekStarts = weekStarts(endingAt: now, count: weekCount, calendar: calendar)
        let knownWeeks = Set(weekStarts)
        var minutes = Dictionary(uniqueKeysWithValues: weekStarts.map { ($0, 0) })

        for item in items where item.isWatched {
            guard let weekStart = weekStart(for: activityDate(for: item), in: knownWeeks, calendar: calendar) else { continue }
            minutes[weekStart, default: 0] += estimatedMinutes(for: item)
        }

        return weekStarts.map { WatchHoursWeek(weekStart: $0, estimatedMinutes: minutes[$0, default: 0]) }
    }

    /// Prefers explicit watchedDate; falls back to lastValuesUpdated for legacy watched rows.
    private static func activityDate(for item: WatchlistItem) -> Date? {
        item.watchedDate ?? item.lastValuesUpdated
    }

    private static func weekStarts(endingAt now: Date, count: Int, calendar: Calendar) -> [Date] {
        guard count > 0 else { return [] }

        var weekStarts: [Date] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -offset, to: now),
                  let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))
            else { continue }
            weekStarts.append(weekStart)
        }
        return weekStarts
    }

    private static func weekStart(for watchedDate: Date?,
                                  in knownWeeks: Set<Date>,
                                  calendar: Calendar) -> Date? {
        guard let watchedDate,
              let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: watchedDate)),
              knownWeeks.contains(weekStart)
        else { return nil }
        return weekStart
    }
}
