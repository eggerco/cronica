//
//  RemindersManager.swift
//  Cronica
//

import Foundation
import CronicaCore
#if canImport(EventKit) && !os(tvOS) && !os(watchOS)
import EventKit
#endif

#if canImport(EventKit) && !os(tvOS) && !os(watchOS)
final class RemindersManager {
    static let shared = RemindersManager()

    private let eventStore = EKEventStore()
    private let reminderIDsKey = "cronicaReminderEventIDs"

    private init() {}

    private var storedReminderIDs: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: reminderIDsKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: reminderIDsKey) }
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, macOS 14.0, *) {
                eventStore.requestFullAccessToReminders { granted, _ in
                    continuation.resume(returning: granted)
                }
            } else {
                eventStore.requestAccess(to: .reminder) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    @MainActor
    func addReminder(for item: WatchlistItem) async throws {
        guard let dueDate = upcomingReminderDate(for: item) else {
            throw ReminderError.noUpcomingDate
        }
        guard await requestAuthorization() else {
            throw ReminderError.accessDenied
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = reminderTitle(for: item)
        reminder.notes = item.itemGlanceInfo
        reminder.url = URL(string: "cronica://\(item.itemContentID)")
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = SettingsStore.shared.notificationHour
        components.minute = SettingsStore.shared.notificationMinute
        reminder.dueDateComponents = components

        try eventStore.save(reminder, commit: true)
        var ids = storedReminderIDs
        ids[item.itemContentID] = reminder.calendarItemIdentifier
        storedReminderIDs = ids
    }

    func removeReminder(identifier contentID: String) {
        guard let reminderID = storedReminderIDs[contentID],
              let reminder = eventStore.calendarItem(withIdentifier: reminderID) as? EKReminder
        else { return }
        try? eventStore.remove(reminder, commit: true)
        var ids = storedReminderIDs
        ids.removeValue(forKey: contentID)
        storedReminderIDs = ids
    }

    func removeAllReminders() {
        for contentID in Array(storedReminderIDs.keys) {
            removeReminder(identifier: contentID)
        }
    }

    @MainActor
    private func upcomingReminderDate(for item: WatchlistItem) -> Date? {
        let date = item.itemUpcomingReleaseDate
        guard date != Date.distantPast else { return nil }
        guard date >= Calendar.current.startOfDay(for: Date()) else { return nil }
        return date
    }

    private func reminderTitle(for item: WatchlistItem) -> String {
        if item.isMovie {
            return String(format: String(localized: "Release: %@"), item.itemTitle)
        }
        return String(format: String(localized: "Next episode: %@"), item.itemTitle)
    }

    enum ReminderError: LocalizedError {
        case noUpcomingDate
        case accessDenied

        var errorDescription: String? {
            switch self {
            case .noUpcomingDate:
                return String(localized: "There isn't an upcoming release or episode date for this title.")
            case .accessDenied:
                return String(localized: "Cronica needs Reminders access to create a reminder.")
            }
        }
    }
}
#else
enum RemindersManager {
    enum ReminderError: LocalizedError {
        case unsupported
    }
}
#endif
