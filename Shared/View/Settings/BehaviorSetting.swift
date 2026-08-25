//
//  BehaviorSetting.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 20/12/22.
//

import SwiftUI
import Nuke

struct BehaviorSetting: View {
    @StateObject private var store = SettingsStore.shared
    @State private var cacheSizeMB: Double = 0.0
    @State private var showClearCacheConfirmation = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var body: some View {
        Form {
#if !os(tvOS)
            Section {
                Picker(selection: $store.gesture) {
                    ForEach(UpdateItemProperties.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    Text("Double Tap On Cover/Poster")
                }
            } header: {
                Text("Gestures")
            } footer: {
                Text("Choose what happens when you double-tap a cover or poster.")
            }
#endif

#if os(iOS)
            Section {
                Picker("Primary Left", selection: $store.primaryLeftSwipe) {
                    ForEach(SwipeGestureOptions.allCases) {
                        Text($0.localizableName).tag($0)
                    }
                }
                Picker("Secondary Left", selection: $store.secondaryLeftSwipe) {
                    ForEach(SwipeGestureOptions.allCases) {
                        Text($0.localizableName).tag($0)
                    }
                }
                Picker("Primary Right", selection: $store.primaryRightSwipe) {
                    ForEach(SwipeGestureOptions.allCases) {
                        Text($0.localizableName).tag($0)
                    }
                }
                Picker("Secondary Right", selection: $store.secondaryRightSwipe) {
                    ForEach(SwipeGestureOptions.allCases) {
                        Text($0.localizableName).tag($0)
                    }
                }
                Toggle("Allow Full Swipe", isOn: $store.allowFullSwipe)
                Button("Reset to Default") {
                    store.primaryLeftSwipe = .markWatch
                    store.secondaryLeftSwipe = .markFavorite
                    store.primaryRightSwipe = .delete
                    store.secondaryRightSwipe = .markArchive
                    store.allowFullSwipe = false
                }
            } header: {
                Text("Swipe Gestures")
            } footer: {
                Text("Full swipe activates the primary action for that edge.")
            }

            Section {
                Toggle("Open Trailers in YouTube", isOn: $store.openInYouTube)
                Toggle("Haptic Feedback", isOn: $store.hapticFeedback)
            } header: {
                Text("Feedback")
            }
#endif

#if os(iOS)
            if horizontalSizeClass == .compact {
                Section {
                    Toggle("Preferred Launch Screen", isOn: $store.isPreferredLaunchScreenEnabled)
                    Picker("Launch Screen", selection: $store.preferredLaunchScreen) {
                        ForEach(Screens.allCases) { item in
                            if item != .notifications, item != .settings {
                                Text(item.title).tag(item)
                            }
                        }
                    }
                    .disabled(!store.isPreferredLaunchScreenEnabled)
                } header: {
                    Text("Launch")
                }
            }
#endif

#if !os(tvOS)
            Section {
                Picker(selection: $store.shareLinkPreference) {
                    ForEach(ShareLinkPreference.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    Text("Sharable Link")
                }
            } header: {
                Text("Sharing")
            } footer: {
                Text("Cronica links open in the app when possible. TMDB links are used when a Cronica link isn’t available.")
            }

            Section {
                Toggle(isOn: $store.disableSearchFilter) {
                    Text("Disable Search Filter")
                }
            } footer: {
                Text("The filter improves results but can make search take longer.")
            }
#endif

            Section {
                Button(String(localized: "Clear Cache \(String(format: "%.1f", cacheSizeMB)) MB"), role: .destructive) {
                    showClearCacheConfirmation = true
                }
                .confirmationDialog(
                    "Clear Cache?",
                    isPresented: $showClearCacheConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear Cache", role: .destructive, action: clearCache)
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Cached images and network responses will be removed. This cannot be undone.")
                }
            } header: {
                Text("Storage")
            }
        }
        .navigationTitle("Behavior")
#if os(macOS)
        .formStyle(.grouped)
#endif
        .onAppear {
            updateCacheSize()
        }
    }
    
    private func clearCache() {
        DataLoader.sharedUrlCache.removeAllCachedResponses()
        ImageCache.shared.removeAll()
        updateCacheSize()
    }
    
    private func updateCacheSize() {
        let totalSizeInBytes = ImageCache.shared.totalCost
        cacheSizeMB = Double(totalSizeInBytes) / (1024 * 1024)
    }
}

#Preview {
    BehaviorSetting()
}
