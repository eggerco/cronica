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
            CronicaFormSection("Behavior") {
                Toggle(isOn: $store.markEpisodeWatchedOnTap) {
                    CronicaFormText("Tap to mark episode as watched")
                }
                Toggle(isOn: $store.askConfirmationToMarkEpisodeWatched) {
                    CronicaFormText("Ask confirmation to mark as watched")
                }
                .disabled(!store.markEpisodeWatchedOnTap)
                Toggle(isOn: $store.preferCoverOnUpNext) {
                    CronicaFormText("Prefer series cover instead of episode thumbnail on Up Next")
                }
                Toggle(isOn: $store.hideUnstartedUpNext) {
                    CronicaFormToggleLabel(
                        title: "Hide unstarted series",
                        subtitle: "Only show series in Up Next after you've watched at least one episode."
                    )
                }
                Toggle(isOn: $store.hideEpisodesTitles) {
                    CronicaFormToggleLabel(
                        title: "Hide titles from unwatched episodes",
                        subtitle: "To avoid potential spoilers, you can hide titles and synopsis from unwatched episodes."
                    )
                }
                Toggle(isOn: $store.hideEpisodesThumbnails) {
                    CronicaFormToggleLabel(
                        title: "Hide thumbnails from unwatched episodes",
                        subtitle: "To avoid potential spoilers, you can hide thumbnails from unwatched episodes."
                    )
                }
            }
            
            CronicaFormSection("Appearance") {
                Picker(selection: $store.upNextSortOrder) {
                    ForEach(UpNextSortOrder.allCases) { item in
                        Text(item.localizableName).tag(item)
                    }
                } label: {
                    CronicaFormText("Up Next sort order")
                }
                Picker(selection: $store.upNextStyle) {
                    ForEach(UpNextDetailsPreferredStyle.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    CronicaFormText("Up Next details style")
                }
            }
            
#if os(macOS)
            Section {
                Toggle(isOn: $store.showMenuBarApp) {
                    CronicaFormText("Show menu bar app")
                }
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
