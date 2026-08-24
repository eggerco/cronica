//
//  NotificationsSettingsView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 12/03/23.
//

import SwiftUI

struct NotificationsSettingsView: View {
    var navigationTitle = "Notifications"
    @StateObject private var settings = SettingsStore.shared
    @Environment(\.openURL) private var openURL
    @State private var currentDate = Date()
    // Computed property to convert stored hour and minute into a Date object
    var notificationTimeBinding: Binding<Date> {
        Binding<Date>(
            get: { self.notificationTime },
            set: { newDate in
                let newComponents = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                settings.notificationHour = newComponents.hour ?? 0
                settings.notificationMinute = newComponents.minute ?? 0
                // Trigger updateNotifications when notification time changes
                Task {
                    await NotificationManager.shared.updateNotifications()
                }
            }
        )
    }
    
    private var notificationTime: Date {
        var components = DateComponents()
        components.hour = settings.notificationHour
        components.minute = settings.notificationMinute
        return Calendar.current.date(from: components) ?? Date()
    }
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $settings.allowNotifications) {
                    CronicaFormText("Allow Notifications")
                }
                Toggle(isOn: $settings.notifyMovieRelease) {
                    CronicaFormToggleLabel(
                        title: "Notify Movies Releases",
                        subtitle: "Notify when a movie on your watchlist is released."
                    )
                }
                .disabled(!settings.allowNotifications)
                Toggle(isOn: $settings.notifyNewEpisodes) {
                    CronicaFormToggleLabel(
                        title: "Notify New Episodes",
                        subtitle: "Notify when a new episode from a TV Show on your watchlist is released."
                    )
                }
                .disabled(!settings.allowNotifications)
                
            }
            .onChange(of: settings.allowNotifications) {
                if !settings.allowNotifications {
                    settings.notifyMovieRelease = false
                    settings.notifyNewEpisodes = false
                }
            }
            
#if !os(tvOS)
            if settings.allowNotifications {
                CronicaFormSection("Notification Time") {
                    DatePicker("Select the hour and minute for notification delivery",
                               selection: notificationTimeBinding,
                               displayedComponents: .hourAndMinute)
                }
                .onAppear {
                    // Set default notification time to 07:00 if not previously set
                    if settings.notificationHour == 0 && settings.notificationMinute == 0 {
                        setDefaultNotificationTime()
                    }
                }
            }
#endif
            
#if os(iOS)
            Button {
                openURL.openNotificationSettings()
            } label: {
                CronicaFormText("Edit Notifications in Settings app")
            }
#endif

#if os(iOS) || os(macOS) || os(visionOS)
            CronicaFormSectionWithFooter("Calendar Sync") {
                Toggle(isOn: $settings.allowCalendarSync) {
                    CronicaFormText("Sync to Calendar")
                }
                Toggle(isOn: $settings.syncCalendarMovies) {
                    CronicaFormToggleLabel(
                        title: "Sync Movie Releases",
                        subtitle: "Add upcoming movie releases from your watchlist to the Cronica calendar."
                    )
                }
                .disabled(!settings.allowCalendarSync)
                Toggle(isOn: $settings.syncCalendarTVShows) {
                    CronicaFormToggleLabel(
                        title: "Sync TV Episodes",
                        subtitle: "Add upcoming TV episodes and season premieres to the Cronica calendar."
                    )
                }
                .disabled(!settings.allowCalendarSync)
                NavigationLink(value: ReleaseCalendarRoute.watchlist) {
                    CronicaFormText("View Release Calendar")
                }
            } footer: {
                CronicaFormFooter("Events are saved to a dedicated Cronica calendar in the Calendar app.")
            }
            .onChange(of: settings.allowCalendarSync) { _, enabled in
                Task {
                    if enabled {
                        await CalendarManager.shared.syncAll()
                    } else {
                        CalendarManager.shared.removeAllEvents()
                    }
                }
            }
            .onChange(of: settings.syncCalendarMovies) { _, _ in
                Task { await CalendarManager.shared.syncAll() }
            }
            .onChange(of: settings.syncCalendarTVShows) { _, _ in
                Task { await CalendarManager.shared.syncAll() }
            }
#endif
        }
        .navigationTitle(NSLocalizedString(navigationTitle, comment: ""))
        .cronicaSettingsForm()
#if os(macOS)
        .navigationDestination(for: ReleaseCalendarRoute.self) { _ in
            ReleaseCalendarView()
        }
#endif
    }
    
    private func setDefaultNotificationTime() {
        settings.notificationHour = 7
        settings.notificationMinute = 0
    }
}

#Preview {
    NotificationsSettingsView()
}
