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
                Toggle("Allow Notifications", isOn: $settings.allowNotifications)
                Toggle(isOn: $settings.notifyMovieRelease) {
                    Text("Notify Movies Releases")
                    Text("Notify when a movie on your watchlist is released.")
                }
                .disabled(!settings.allowNotifications)
                Toggle(isOn: $settings.notifyNewEpisodes) {
                    Text("Notify New Episodes")
                    Text("Notify when a new episode from a TV Show on your watchlist is released.")
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
                Section("Notification Time") {
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
            Button("Edit Notifications in Settings app") {
                openURL.openNotificationSettings()
            }
#endif
        }
        .navigationTitle(NSLocalizedString(navigationTitle, comment: ""))
        .cronicaSettingsForm()
    }
    
    private func setDefaultNotificationTime() {
        settings.notificationHour = 7
        settings.notificationMinute = 0
    }
}

#Preview {
    NotificationsSettingsView()
}
