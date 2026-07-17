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
    @State private var showExportShareSheet = false
    @State private var showFilePicker = false
    @State private var exportUrl: URL?
    @Environment(\.managedObjectContext) private var context
    @State private var isImporting = false
    @State private var importMessage: String?
    @State private var showImportResult = false
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
                exportButton
#endif
            } header: {
#if !os(macOS)
                Text("Backup & Restore")
#endif
            } footer: {
#if os(iOS)
                Text("Exports your watchlist as JSON. Restore skips titles that are already in your library.")
#endif
            }
            .sheet(isPresented: $showExportShareSheet) {
#if os(iOS)
                CustomShareSheet(url: $exportUrl)
#endif
            }
#if os(iOS)
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let success):
                    importJSON(success)
                case .failure(let failure):
                    CronicaTelemetry.shared.handleMessage(failure.localizedDescription, for: "SyncSettings.fileImporter")
                    importMessage = String(localized: "Couldn’t open that file.")
                    showImportResult = true
                }
            }
            .alert("Restore", isPresented: $showImportResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importMessage ?? "")
            }
#endif
#endif
        }
        .navigationTitle("Watchlist Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
#endif
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
    
#if os(iOS)
    private var importButton: some View {
        Button {
            showFilePicker.toggle()
        } label: {
            if isImporting {
                ProgressView()
            } else {
                Text("Restore")
            }
        }
        .disabled(isImporting)
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
            await background.handleWatchingContentRefresh(force: true)
            await background.handleUpcomingContentRefresh(force: true)
            await background.handleAppRefreshMaintenance(force: true)
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
            if let entityName = WatchlistItem.entity().name {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let items = try context.fetch(request).compactMap {
                    $0 as? WatchlistItem
                }
                let jsonData = try JSONEncoder().encode(items)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    if let tempUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let formatter = DateFormatter()
                        formatter.locale = Locale(identifier: "en_US_POSIX")
                        formatter.dateFormat = "yyyy-MM-dd"
                        let pathUrl = tempUrl.appending(component: "CronicaExport-\(formatter.string(from: Date())).json")
                        try jsonString.write(to: pathUrl, atomically: true, encoding: .utf8)
                        exportUrl = pathUrl
                        showExportShareSheet.toggle()
                    }
                }
            }
            isGeneratingExport = false
        } catch {
            isGeneratingExport = false
            CronicaTelemetry.shared.handleMessage(error.localizedDescription, for: "SyncSettings.export.failed")
        }
    }
    
    private func importJSON(_ url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        isImporting = true
        defer { isImporting = false }
        do {
            let existingRequest = WatchlistItem.fetchRequest()
            let existingItems = try context.fetch(existingRequest)
            var existingIDs = Set(existingItems.compactMap(\.contentID))

            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.userInfo[.context] = context
            let decoded = try decoder.decode([WatchlistItem].self, from: jsonData)
            var imported = 0
            var skipped = 0
            for item in decoded {
                let id = item.contentID ?? item.itemContentID
                if existingIDs.contains(id) {
                    context.delete(item)
                    skipped += 1
                } else {
                    existingIDs.insert(id)
                    imported += 1
                }
            }
            try context.save()
            importMessage = String(
                format: String(localized: "Imported %lld titles. Skipped %lld that were already in your watchlist."),
                imported,
                skipped
            )
            showImportResult = true
        } catch {
            CronicaTelemetry.shared.handleMessage(error.localizedDescription, for: "SyncSettings.importJSON.failed")
            importMessage = String(localized: "Restore failed. Check that the file is a Cronica backup.")
            showImportResult = true
        }
    }
#endif
}

#if os(iOS)
private struct CustomShareSheet: UIViewControllerRepresentable {
    @Binding var url: URL?
    func makeUIViewController(context: Context) -> some UIViewController {
        if let url {
            return UIActivityViewController(activityItems: [url], applicationActivities: nil)
        }
        return UIActivityViewController(activityItems: [], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
#endif
