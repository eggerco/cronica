//
//  CalendarManager.swift
//  Cronica
//

import Foundation
import CoreData
import CronicaCore
#if canImport(EventKit) && !os(tvOS) && !os(watchOS)
import EventKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
#endif

#if canImport(EventKit) && !os(tvOS) && !os(watchOS)
final class CalendarManager {
    static let shared = CalendarManager()

    private let eventStore = EKEventStore()
    private let calendarTitle = "Cronica"
    private let eventIDsKey = "cronicaCalendarEventIDs"

    private init() {}

    private var storedEventIDs: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: eventIDsKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: eventIDsKey) }
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, macOS 14.0, *) {
                eventStore.requestFullAccessToEvents { granted, _ in
                    continuation.resume(returning: granted)
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func schedule(_ content: ItemContent) {
        let settings = SettingsStore.shared
        guard settings.allowCalendarSync else { return }
        guard shouldSync(content) else { return }
        guard let releaseDate = releaseDate(for: content) else { return }
        guard releaseDate >= Calendar.current.startOfDay(for: Date()) else { return }

        Task {
            guard await requestAuthorization() else { return }
            upsertEvent(
                identifier: content.itemContentID,
                title: content.itemTitle,
                notes: eventNotes(for: content),
                url: content.cronicaDeepLinkURL,
                releaseDate: releaseDate
            )
        }
    }

    func schedule(_ item: WatchlistItem) {
        let settings = SettingsStore.shared
        guard settings.allowCalendarSync else { return }
        guard shouldSync(item) else { return }
        guard let releaseDate = releaseDate(for: item) else { return }
        guard releaseDate >= Calendar.current.startOfDay(for: Date()) else { return }

        Task {
            guard await requestAuthorization() else { return }
            upsertEvent(
                identifier: item.itemContentID,
                title: item.itemTitle,
                notes: item.itemGlanceInfo,
                url: URL(string: "cronica://\(item.itemContentID)"),
                releaseDate: releaseDate
            )
        }
    }

    func removeEvent(identifier: String) {
        guard let eventID = storedEventIDs[identifier] else { return }
        if let event = eventStore.event(withIdentifier: eventID) {
            try? eventStore.remove(event, span: .thisEvent, commit: true)
        }
        var ids = storedEventIDs
        ids.removeValue(forKey: identifier)
        storedEventIDs = ids
    }

    func removeAllEvents() {
        for identifier in Array(storedEventIDs.keys) {
            removeEvent(identifier: identifier)
        }
    }

    func syncAll() async {
        guard SettingsStore.shared.allowCalendarSync else {
            removeAllEvents()
            return
        }
        guard await requestAuthorization() else { return }

        let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
        request.predicate = NSPredicate(format: "isArchive == NO")

        let context = PersistenceController.shared.container.viewContext
        guard let items = try? context.fetch(request) else { return }

        var activeIDs = Set<String>()
        let startOfToday = Calendar.current.startOfDay(for: Date())

        for item in items {
            guard shouldSync(item) else { continue }
            guard let releaseDate = releaseDate(for: item), releaseDate >= startOfToday else { continue }
            activeIDs.insert(item.itemContentID)
            upsertEvent(
                identifier: item.itemContentID,
                title: item.itemTitle,
                notes: item.itemGlanceInfo,
                url: URL(string: "cronica://\(item.itemContentID)"),
                releaseDate: releaseDate
            )
        }

        for identifier in storedEventIDs.keys where !activeIDs.contains(identifier) {
            removeEvent(identifier: identifier)
        }
    }

    private func shouldSync(_ content: ItemContent) -> Bool {
        let settings = SettingsStore.shared
        switch content.itemContentMedia {
        case .movie: return settings.syncCalendarMovies
        case .tvShow: return settings.syncCalendarTVShows
        default: return false
        }
    }

    private func shouldSync(_ item: WatchlistItem) -> Bool {
        let settings = SettingsStore.shared
        if item.isMovie { return settings.syncCalendarMovies }
        if item.isTvShow { return settings.syncCalendarTVShows }
        return false
    }

    private func releaseDate(for content: ItemContent) -> Date? {
        if content.itemContentMedia == .movie {
            return content.itemTheatricalDate ?? content.itemFallbackDate
        }
        if content.itemContentMedia == .tvShow {
            return content.nextEpisodeDate ?? content.itemFallbackDate
        }
        return content.itemFallbackDate
    }

    private func releaseDate(for item: WatchlistItem) -> Date? {
        let date = item.itemUpcomingReleaseDate
        if date == Date.distantPast { return item.itemDate }
        return date
    }

    private func eventNotes(for content: ItemContent) -> String? {
        if content.itemContentMedia == .tvShow, let episode = content.nextEpisodeToAir {
            if let name = episode.name, !name.isEmpty {
                return "S\(episode.seasonNumber) E\(episode.episodeNumber) • \(name)"
            }
            return "S\(episode.seasonNumber) E\(episode.episodeNumber)"
        }
        if let overview = content.overview, !overview.isEmpty {
            return overview
        }
        return nil
    }

    private func cronicaCalendar() -> EKCalendar? {
        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == calendarTitle }) {
            return existing
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarTitle
#if canImport(UIKit)
        calendar.cgColor = UIColor.systemBlue.cgColor
#elseif canImport(AppKit)
        calendar.color = .systemBlue
#endif

        if let source = eventStore.defaultCalendarForNewEvents?.source ?? eventStore.sources.first {
            calendar.source = source
        } else {
            return eventStore.defaultCalendarForNewEvents
        }

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return calendar
        } catch {
            CronicaTelemetry.shared.handleMessage(error.localizedDescription, for: "CalendarManager.createCalendar")
            return eventStore.defaultCalendarForNewEvents
        }
    }

    private func upsertEvent(
        identifier: String,
        title: String,
        notes: String?,
        url: URL?,
        releaseDate: Date
    ) {
        guard let calendar = cronicaCalendar() else { return }

        let event: EKEvent
        if let existingID = storedEventIDs[identifier], let existing = eventStore.event(withIdentifier: existingID) {
            event = existing
        } else {
            event = EKEvent(eventStore: eventStore)
        }

        let start = Calendar.current.startOfDay(for: releaseDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)

        event.calendar = calendar
        event.title = title
        event.notes = notes
        event.url = url
        event.isAllDay = true
        event.startDate = start
        event.endDate = end

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            var ids = storedEventIDs
            ids[identifier] = event.eventIdentifier
            storedEventIDs = ids
        } catch {
            CronicaTelemetry.shared.handleMessage(error.localizedDescription, for: "CalendarManager.saveEvent")
        }
    }
}
#else
final class CalendarManager {
    static let shared = CalendarManager()
    private init() {}
    func requestAuthorization() async -> Bool { false }
    func schedule(_ content: ItemContent) { }
    func schedule(_ item: WatchlistItem) { }
    func removeEvent(identifier: String) { }
    func removeAllEvents() { }
    func syncAll() async { }
}
#endif
