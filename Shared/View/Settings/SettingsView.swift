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
    @State private var showPrivacyDataSheet = false
#elseif os(tvOS)
    @StateObject private var store = SettingsStore.shared
#endif
    var body: some View {
        settings
    }
    
    private var settings: some View {
#if os(iOS) || os(visionOS)
        Form {
            CronicaFormSection("General") {
                NavigationLink(value: SettingsScreens.appearance) {
                    settingsLabel(title: NSLocalizedString("Appearance", comment: ""),
                                  icon: "paintbrush", color: .blue)
                }
                NavigationLink(value: SettingsScreens.behavior) {
                    settingsLabel(title: NSLocalizedString("Behavior", comment: ""),
                                  icon: "hand.tap", color: .gray)
                }
                NavigationLink(value: SettingsScreens.notifications) {
                    settingsLabel(title: NSLocalizedString("Notifications", comment: ""),
                                  icon: "bell", color: .red)
                }
            }
            
            CronicaFormSection("Features") {
                NavigationLink(value: SettingsScreens.watchlist) {
                    settingsLabel(title: NSLocalizedString("Watchlist", comment: ""),
                                  icon: "rectangle.on.rectangle", color: AppThemeColors.goldenrod.color)
                }
                NavigationLink(value: SettingsScreens.season) {
                    settingsLabel(title: NSLocalizedString("Season & Up Next", comment: ""),
                                  icon: "tv", color: AppThemeColors.turquoiseBlue.color)
                }
                NavigationLink(value: SettingsScreens.region) {
                    settingsLabel(title: NSLocalizedString("Watch Provider", comment: ""),
                                  icon: "globe", color: .purple)
                }
            }
            
            CronicaFormSection("About") {
                NavigationLink(value: SettingsScreens.about) {
                    settingsLabel(title: NSLocalizedString("About", comment: ""),
                                  icon: "info.circle", color: .black)
                }
                Button {
                    showPrivacyDataSheet = true
                } label: {
                    settingsLabel(title: String(localized: "Privacy & Data"),
                                  icon: "lock.shield", color: .orange)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("Privacy & Data Settings Button")
                NavigationLink(value: SettingsScreens.feedback) {
                    settingsLabel(title: NSLocalizedString("Feedback", comment: ""),
                                  icon: "envelope.fill", color: AppThemeColors.steel.color)
                }
#if !os(visionOS)
                NavigationLink(value: SettingsScreens.tipJar) {
                    settingsLabel(title: NSLocalizedString("Tip Jar", comment: ""),
                                  icon: "heart", color: .red)
                }
#endif
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .cronicaSettingsForm()
        .accessibilityIdentifier("Settings View")
        .sheet(isPresented: $showPrivacyDataSheet) {
            NavigationStack {
                DataManagementSettingsView()
                    .nativeSheetDismissToolbar { showPrivacyDataSheet = false }
            }
#if os(iOS) || os(visionOS)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
#endif
            .appTheme()
            .appTint()
        }
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
            .cronicaSettingsForm()
        }
#endif
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
            Text(verbatim: title)
                .textCase(nil)
                .environment(\.textCase, nil)
        }
        .padding(.vertical, 2)
        .environment(\.textCase, nil)
    }
}

#Preview {
    SettingsView()
}
