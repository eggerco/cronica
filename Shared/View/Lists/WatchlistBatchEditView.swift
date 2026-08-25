//
//  WatchlistBatchEditView.swift
//  Cronica
//

import SwiftUI
import CoreData

/// Multi-select bulk actions for watchlist / custom list items.
struct WatchlistBatchEditView: View {
    let items: [WatchlistItem]
    @Binding var isPresented: Bool
    @State private var selection = Set<NSManagedObjectID>()
    @State private var showDeleteConfirm = false
    private let persistence = PersistenceController.shared

    var body: some View {
        NavigationStack {
            List(selection: $selection) {
                ForEach(items, id: \.objectID) { item in
                    HStack {
                        Text(item.itemTitle)
                        Spacer()
                        if item.isWatched {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(item.objectID)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Select Items")
#if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        applyWatched(true)
                    } label: {
                        Label("Watched", systemImage: "checkmark.circle")
                    }
                    .disabled(selection.isEmpty)

                    Button {
                        applyArchive()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .disabled(selection.isEmpty)

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selection.isEmpty)
                }
            }
            .confirmationDialog("Delete Selected?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete \(selection.count) Items", role: .destructive, action: applyDelete)
            } message: {
                Text("This removes the selected titles from your watchlist.")
            }
        }
    }

    private var selectedItems: [WatchlistItem] {
        items.filter { selection.contains($0.objectID) }
    }

    private func applyWatched(_ watched: Bool) {
        for item in selectedItems where item.isWatched != watched {
            persistence.updateWatched(for: item)
        }
        selection.removeAll()
    }

    private func applyArchive() {
        for item in selectedItems where !item.isArchive {
            persistence.updateArchive(for: item)
        }
        selection.removeAll()
    }

    private func applyDelete() {
        for item in selectedItems {
            persistence.delete(item)
        }
        selection.removeAll()
        isPresented = false
    }
}
