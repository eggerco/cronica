//
//  WatchlistSettingsView.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 25/01/24.
//

import SwiftUI
import CoreData

struct WatchlistSettingsView: View {
    @StateObject private var store = SettingsStore.shared
    @State private var updatingItems = false
    @State private var isGeneratingExport = false
    @State private var showFilePicker = false
    @State private var exportUrl: URL?
    @Environment(\.managedObjectContext) private var context
    @State private var hasImported = false
    let background = BackgroundManager.shared
    var body: some View {
        Form {
            Section("Behavior") {
#if os(iOS) || os(macOS)
                Toggle("Open List Selector when adding an item", isOn: $store.openListSelectorOnAdding)
#endif
                Toggle("Remove From Pin when item is  marked as watched", isOn: $store.removeFromPinOnWatched)
                Toggle("Show Remove Confirmation", isOn: $store.showRemoveConfirmation)
            }
            
            Section("Appearance") {
                Picker(selection: $store.watchlistStyle) {
                    ForEach(SectionDetailsPreferredStyle.allCases) { item in
#if os(tvOS)
                        if item != SectionDetailsPreferredStyle.list {
                            Text(item.title).tag(item)
                        }
#else
                        Text(item.title).tag(item)
#endif
                    }
                } label: {
                    Text("Watchlist's Item Style")
                }
#if !os(tvOS)
                Toggle("Show Date in Watchlist", isOn: $store.showDateOnWatchlist)
#endif
            }
            
            Section("Sync") {
                Button {
                    updateItems()
                } label: {
                    if updatingItems {
                        CenterHorizontalView {
                            ProgressView()
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("Update Items")
                            Text("Update items with new information, if available on TMDb")
                                .foregroundColor(.secondary)
                        }
                    }
                }
#if os(macOS)
                .buttonStyle(.plain)
#endif
            }
#if !os(tvOS)
            Section {
#if os(iOS)
                importButton
                if let exportUrl {
                    ShareLink(item: exportUrl) {
                        Text("Backup")
                    }
                    .disabled(isGeneratingExport)
                } else {
                    exportButton
                }
#endif
            } header: {
#if !os(macOS)
                Text("Backup & Restore")
#endif
            } footer: {
#if os(iOS)
                Text("Backup/Restore is in beta, only use it to export your data or to import if you're switching your iCloud account, there's no logic at the moment to avoid duplication.")
#endif
            }
#if os(iOS)
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let success):
                    if success.startAccessingSecurityScopedResource() {
                        importJSON(success)
                    }
                case .failure(let failure):
                    CronicaTelemetry.shared.handleMessage(failure.localizedDescription, for: "SyncSettings.fileImporter")
                }
            }
#endif
#endif
        }
        .navigationTitle("Watchlist Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .cronicaSettingsForm()
    }
    
#if os(iOS)
    private var importButton: some View {
        Button {
            showFilePicker.toggle()
        } label: {
            Text("Restore")
        }
        .disabled(hasImported)
    }
    
    private var exportButton: some View {
        Button {
            export()
        } label: {
            if isGeneratingExport {
                CenterHorizontalView {
                    ProgressView("Generating File")
                }
            } else {
                Text("Backup")
            }
        }
        .disabled(isGeneratingExport)
    }
#endif
}

#Preview {
    WatchlistSettingsView()
}

extension WatchlistSettingsView {
    @MainActor
    private func updateItems() {
        Task {
            await MainActor.run {
                withAnimation {
                    self.updatingItems.toggle()
                }
            }
            await background.handleWatchingContentRefresh()
            await background.handleUpcomingContentRefresh()
            await background.handleAppRefreshMaintenance()
            await MainActor.run {
                withAnimation {
                    self.updatingItems.toggle()
                }
            }
        }
    }
    
#if os(iOS)
    private func export() {
        do {
            isGeneratingExport = true
            let request = WatchlistItem.fetchRequest()
            let items = try context.fetch(request)
            let jsonData = try JSONEncoder().encode(items)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                if let tempUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let pathUrl = tempUrl.appending(component: "CronicaExport \(Date().formatted(date: .abbreviated, time: .omitted)).json")
                    try jsonString.write(to: pathUrl, atomically: true, encoding: .utf8)
                    exportUrl = pathUrl
                }
            }
            isGeneratingExport = false
        } catch {
            isGeneratingExport = false
            CronicaTelemetry.shared.handleMessage(error.localizedDescription, for: "SyncSettings.export.failed")
        }
    }
    
    private func importJSON(_ url: URL) {
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.userInfo[.context] = PersistenceController.shared.container.viewContext
            _ = try decoder.decode([WatchlistItem].self, from: jsonData)
            try context.save()
            hasImported.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    hasImported = false
                }
            }
        } catch {
            CronicaTelemetry.shared.handleMessage(error.localizedDescription, for: "SyncSettings.importJSON.failed")
        }
    }
#endif
}
