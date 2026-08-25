//
//  SettingsView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 22/03/22.
//

import SwiftUI

/// Renders the Settings UI for each OS, support iOS, macOS, and tvOS.
struct SettingsView: View {
#if os(iOS) || os(visionOS)
    static let tag: Screens? = .settings
#elseif os(tvOS)
    @StateObject private var store = SettingsStore.shared
#endif
    var body: some View {
        settings
    }
    
    private var settings: some View {
#if os(iOS) || os(visionOS)
        Form {
            Section("General") {
                settingsNavigationLink(.appearance, title: String(localized: "Appearance"), icon: "paintbrush", color: .blue)
                settingsNavigationLink(.behavior, title: String(localized: "Behavior"), icon: "hand.tap", color: .gray)
                settingsNavigationLink(.notifications, title: String(localized: "Notifications"), icon: "bell", color: .red)
            }
            
            Section("Features") {
                settingsNavigationLink(.watchlist, title: String(localized: "Watchlist"), icon: "rectangle.on.rectangle", color: AppThemeColors.goldenrod.color)
                settingsNavigationLink(.season, title: String(localized: "Season & Up Next"), icon: "tv", color: AppThemeColors.turquoiseBlue.color)
                settingsNavigationLink(.region, title: String(localized: "Watch Provider"), icon: "globe", color: .purple)
            }
            
            Section("About") {
                settingsNavigationLink(.about, title: String(localized: "About"), icon: "info.circle", color: .black)
                settingsNavigationLink(.dataManagement, title: String(localized: "Privacy & Data"), icon: "lock.shield", color: .orange)
                settingsNavigationLink(.feedback, title: String(localized: "Feedback"), icon: "envelope.fill", color: AppThemeColors.steel.color)
#if !os(visionOS)
                settingsNavigationLink(.tipJar, title: String(localized: "Tip Jar"), icon: "heart", color: .red)
#endif
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .accessibilityIdentifier("Settings View")
#elseif os(macOS)
        TabView {
            AppearanceSetting()
                .tabItem { Label("Appearance", systemImage: "moon.stars") }
            
            BehaviorSetting()
                .tabItem { Label("Behavior", systemImage: "cursorarrow.click") }
            
            NavigationStack {
                NotificationsSettingsView()
                    .cronicaWatchlistNavigationDestinations()
            }
                .tabItem { Label("Notifications", systemImage: "bell") }
            
            WatchlistSettingsView()
                .tabItem { Label("Watchlist", systemImage: "rectangle.on.rectangle") }
            
            SeasonUpNextSettingsView()
                .tabItem { Label("Season & Up Next", systemImage: "tv") }
            
            WatchProviderSettings()
                .tabItem { Label("Region", systemImage: "globe")  }

            NavigationStack {
                DataManagementSettingsView()
            }
            .tabItem { Label("Privacy & Data", systemImage: "lock.shield") }
            
            TipJarSetting()
                .tabItem { Label("Tip Jar", systemImage: "heart") }
        }
        .frame(minWidth: 420, idealWidth: 500, minHeight: 320, idealHeight: 320)
        .tabViewStyle(.automatic)
#elseif os(tvOS)
        NavigationStack {
            Form {
                Section {
                    NavigationLink("Watchlist", destination: WatchlistSettingsView())
                    NavigationLink("Appearance", destination: AppearanceSetting())
                }
                
                Section {
                    NavigationLink("Tip Jar", destination: TipJarSetting())
                }
            }
            .navigationTitle("Settings")
        }
#endif
    }

#if os(iOS) || os(visionOS)
    private func settingsNavigationLink(
        _ value: SettingsScreens,
        title: String,
        icon: String,
        color: Color
    ) -> some View {
        NavigationLink(value: value) {
            settingsLabel(title: title, icon: icon, color: color)
        }
    }

    private func settingsLabel(title: String, icon: String, color: Color) -> some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(color)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Image(systemName: icon)
                    .foregroundColor(.white)
            }
            .frame(width: 30, height: 30, alignment: .center)
            .padding(.trailing, 8)
            .accessibilityHidden(true)
            Text(title)
        }
        .padding(.vertical, 2)
    }
#endif
}

#Preview {
    SettingsView()
}
