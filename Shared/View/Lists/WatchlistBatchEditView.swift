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
    /// Called with the visible items in their new order after a drag; nil disables reordering.
    var onReorder: (([WatchlistItem]) -> Void)?
    @State private var orderedItems: [WatchlistItem] = []
    @State private var selection = Set<NSManagedObjectID>()
    @State private var showDeleteConfirm = false
    private let persistence = PersistenceController.shared

    var body: some View {
        NavigationStack {
            List(selection: $selection) {
                Section {
                    ForEach(orderedItems, id: \.objectID) { item in
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
                    .onMove(perform: onReorder == nil ? nil : move)
                } footer: {
                    if onReorder != nil {
                        Text("Drag to reorder. The list then uses Manual Order.")
                    }
                }
            }
            .onAppear { orderedItems = items }
            .onChange(of: items.map(\.objectID)) { orderedItems = items }
#if os(iOS) || os(visionOS)
            .environment(\.editMode, .constant(.active))
#endif
            .navigationTitle("Select Items")
#if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
#if os(iOS) || os(visionOS)
                ToolbarItemGroup(placement: .bottomBar) {
                    batchActionButtons
                }
#else
                ToolbarItemGroup(placement: .primaryAction) {
                    batchActionButtons
                }
#endif
            }
            .confirmationDialog("Delete Selected?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete \(selection.count) Items", role: .destructive, action: applyDelete)
            } message: {
                Text("This removes the selected titles from your watchlist.")
            }
        }
    }

    @ViewBuilder
    private var batchActionButtons: some View {
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

    private func move(from source: IndexSet, to destination: Int) {
        orderedItems.move(fromOffsets: source, toOffset: destination)
        onReorder?(orderedItems)
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
