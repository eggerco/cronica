//
//  LocalNotificationManager.swift
//  Cronica
//
//  Created by Alexandre Madeira on 08/03/22.
//

import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private var settings: UNNotificationSettings?
    private init() { }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .provisional]) { granted, error in
            self.fetchNotificationSettings()
            completion(granted)
        }
    }
    
    func fetchNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.settings = settings
            }
        }
    }
    
    func isNotificationAllowed() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    func schedule(_ content: ItemContent) {
        let settings = SettingsStore.shared
        let type = content.itemContentMedia
        if !settings.allowNotifications { return }
        if type == .movie {
            if !settings.notifyMovieRelease { return }
        } else {
            if !settings.notifyNewEpisodes { return }
        }
        self.requestAuthorization { granted in
            if !granted {
                return
            }
        }
        let identifier = content.itemContentID
        let title = content.itemTitle
        var body: String
        body = content.itemContentMedia == .movie ? String(localized: "The movie will be released today.") : String(localized: "Next episode arrives today.")
        var date: Date?
        if content.itemContentMedia == .movie {
            date = content.itemTheatricalDate
        } else if content.itemContentMedia == .tvShow {
            date = content.nextEpisodeDate
        } else {
            date = content.itemFallbackDate
        }
        guard let date else { return }
        if date.isLessThanTwoWeeksAway() {
            removeNotification(identifier: content.itemContentID)
            self.scheduleNotification(identifier: identifier,
                                      title: title,
                                      message: body,
                                      date: date)
        }
    }
    
    private func scheduleNotification(identifier: String, title: String, message: String, date: Date) {
#if os(tvOS)
#else
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = message
        notificationContent.userInfo = ["contentID":"\(identifier)"]
        notificationContent.sound = UNNotificationSound.default
        var dateComponent: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second],
                                                                            from: date)
        dateComponent.hour = SettingsStore.shared.notificationHour
        dateComponent.minute = SettingsStore.shared.notificationMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: notificationContent,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
#endif
    }
    
    func removeNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func removeDeliveredNotification(identifier: String) {
#if os(tvOS)
#else
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
#endif
    }
    
    func removeAllDeliveredNotifications() {
#if os(tvOS)
#else
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
#endif
    }
    
    private func getUpcomingNotificationsId() async -> [String] {
        var identifiers = [String]()
        let notifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
        for item in notifications {
            identifiers.append(item.identifier)
        }
        return identifiers
    }
    
    private func getDeliveredNotificationsId() async -> [String] {
#if os(tvOS)
        return []
#else
        var identifiers = [String]()
        let notifications = await UNUserNotificationCenter.current().deliveredNotifications()
        if notifications.isEmpty {
            return identifiers
        } else {
            for item in notifications {
                if item.request.identifier.contains("@") {
                    identifiers.append(item.request.identifier)
                }
            }
        }
        return identifiers
#endif
    }
    
    func fetchDeliveredNotifications() async -> [ItemContent] {
        var items = [ItemContent]()
        let notifications = await getDeliveredNotificationsId()
        if notifications.isEmpty { return items }
        for notification in notifications {
            let type = notification.last ?? "0"
            var media: MediaType = .movie
            if type == "1" {
                media = .tvShow
            }
            let id = notification.dropLast(2)
            guard let contentID = Int(id) else { return [] }
            let item = try? await NetworkService.shared.fetchItem(id: contentID, type: media)
            if let item {
                items.append(item)
            }
        }
        return items
    }
    
    func hasDeliveredItems() async -> Bool {
        let notifications = await getDeliveredNotificationsId()
        if notifications.isEmpty { return false }
        return true
    }
    
    func fetchUpcomingNotifications() async throws -> [WatchlistItem] {
        var items = [WatchlistItem]()
        let notifications = await getUpcomingNotificationsId()
        for notification in notifications {
            let item = PersistenceController.shared.fetch(for: notification)
            if let item {
                items.append(item)
            }
        }
        return items
    }
    
    func fetchUpcomingNotifications() async -> [ItemContent]? {
        var identifiers = [String]()
        let notifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
        for item in notifications {
            if item.identifier.contains("@") {
                identifiers.append(item.identifier)
            }
        }
        var items = [ItemContent]()
        if identifiers.isEmpty {
            return items
        }
        let service = NetworkService.shared
        for identifier in identifiers {
            let type = identifier.last ?? "0"
            var media: MediaType = .movie
            if type == "1" {
                media = .tvShow
            }
            let id = identifier.dropLast(2)
            guard let itemId = Int(id) else { continue }
            do {
                let item = try await service.fetchItem(id: itemId, type: media)
                items.append(item)
            } catch {
                continue
            }
        }
        return items
    }
    
    func hasPendingNotification(for id: String) async -> Bool {
        let notifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
        if notifications.contains(where: { $0.identifier == id }) { return true }
        return false
    }
    
    func updateNotifications() async {
        let upcomingNotifications:[ItemContent]? = await self.fetchUpcomingNotifications()
        guard let upcomingNotifications else { return }
        for notification in upcomingNotifications {
            removeNotification(identifier: notification.itemContentID)
            schedule(notification)
        }
    }
}
