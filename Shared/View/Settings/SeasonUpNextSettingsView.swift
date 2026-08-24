//
//  SeasonUpNextSettingsView.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 25/01/24.
//

import SwiftUI

struct SeasonUpNextSettingsView: View {
    @StateObject private var store = SettingsStore.shared
    var body: some View {
        Form {
            Section("Behavior") {
                Toggle(isOn: $store.markEpisodeWatchedOnTap) {
                    Text("Tap To Mark Episode as Watched")
                }
                Toggle("Ask Confirmation To Mark as Watched", isOn: $store.askConfirmationToMarkEpisodeWatched)
                    .disabled(!store.markEpisodeWatchedOnTap)
                Toggle(isOn: $store.preferCoverOnUpNext) {
                    Text("Prefer Series Cover instead of Episode Thumbnail on Up Next")
                }
                Toggle(isOn: $store.hideUnstartedUpNext) {
                    Text("Hide Unstarted Series")
                    Text("Only show series in Up Next after you've watched at least one episode.")
                }
                Toggle(isOn: $store.hideEpisodesTitles) {
                    Text("Hide Titles from Unwatched Episodes")
                    Text("To avoid potential spoilers, you can hide titles and synopsis from unwatched episodes.")
                }
                Toggle(isOn: $store.hideEpisodesThumbnails) {
                    Text("Hide Thumbnails from Unwatched Episodes")
                    Text("To avoid potential spoilers, you can hide thumbnails from unwatched episodes.")
                }
            }
            
            Section("Appearance") {
                Picker(selection: $store.upNextSortOrder) {
                    ForEach(UpNextSortOrder.allCases) { item in
                        Text(item.localizableName).tag(item)
                    }
                } label: {
                    Text("Up Next Sort Order")
                }
                Picker(selection: $store.upNextStyle) {
                    ForEach(UpNextDetailsPreferredStyle.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    Text("Up Next Details Style")
                }
            }
            
#if os(macOS)
            Section {
                Toggle("Show Menu Bar App", isOn: $store.showMenuBarApp)
            }
#endif
        }
        .navigationTitle("Season & Up Next Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .cronicaSettingsForm()
    }
}

#Preview {
    SeasonUpNextSettingsView()
}
