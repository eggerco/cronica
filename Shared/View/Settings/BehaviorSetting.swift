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
            Section("Gestures") {
                Picker(selection: $store.gesture) {
                    ForEach(UpdateItemProperties.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    Text("Double Tap On Cover/Poster")
                }
            } footer: {
                Text("Choose what function to perform when double tap the cover/poster image.")
            }
#endif

#if os(iOS)
            Section("Swipe Gestures") {
                Picker("Primary Left Gesture", selection: $store.primaryLeftSwipe) {
                    ForEach(SwipeGestureOptions.allCases) {
                        Text($0.localizableName).tag($0)
                    }
                }
                Picker("Secondary Left Gesture", selection: $store.secondaryLeftSwipe) {
                    ForEach(SwipeGestureOptions.allCases) {
                        Text($0.localizableName).tag($0)
                    }
                }
                Picker("Primary Right Gesture", selection: $store.primaryRightSwipe) {
                    ForEach(SwipeGestureOptions.allCases) {
                        Text($0.localizableName).tag($0)
                    }
                }
                Picker("Secondary Right Gesture", selection: $store.secondaryRightSwipe) {
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
            } footer: {
                Text("Full Swipe will activate the primary action")
            }

            Section("Feedback") {
                Toggle("Open Trailers in YouTube", isOn: $store.openInYouTube)
                Toggle("Haptic Feedback", isOn: $store.hapticFeedback)
            }

            if horizontalSizeClass == .compact {
                Section("Launch") {
                    Toggle("Enable Preferred Launch Screen", isOn: $store.isPreferredLaunchScreenEnabled)
                    Picker("Preferred Launch Screen", selection: $store.preferredLaunchScreen) {
                        ForEach(Screens.allCases) { item in
                            if item != .notifications, item != .settings {
                                Text(item.title).tag(item)
                            }
                        }
                    }
                    .disabled(!store.isPreferredLaunchScreenEnabled)
                }
            }
#endif

#if !os(tvOS)
            Section("Sharing") {
                Picker(selection: $store.shareLinkPreference) {
                    ForEach(ShareLinkPreference.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    Text("Sharable Link")
                }
            } footer: {
                Text("You can choose to share using a Cronica link that will allow you to open the application.\nPlease note that not all content can be shared with a Cronica link, the application will always use TMDB links if necessary.")
            }

            Section {
                Toggle(isOn: $store.disableSearchFilter) {
                    Text("Disable Search Filter")
                }
            } footer: {
                Text("Search filter improve the search results, but has the downside of taking longer to load.")
            }
#endif

            Section("Storage") {
                Button("Clear Cache (\(String(format: "%.1f", cacheSizeMB)) MB)", role: .destructive) {
                    showClearCacheConfirmation = true
                }
            }
        }
        .navigationTitle("Behavior")
        .cronicaSettingsForm()
        .onAppear {
            updateCacheSize()
        }
        .confirmationDialog("Clear Cache?", isPresented: $showClearCacheConfirmation, titleVisibility: .visible) {
            Button("Clear Cache", role: .destructive, action: clearCache)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Cached images and network responses will be removed. This cannot be undone.")
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
