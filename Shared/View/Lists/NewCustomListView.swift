//
//  NewCustomListView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 08/02/23.
//

import SwiftUI

struct NewCustomListView: View {
#if os(macOS)
    @Binding var isPresentingNewList: Bool
#endif
    @Binding var presentView: Bool
    var preSelectedItem: WatchlistItem?
    @State private var title = ""
    @State private var note = ""
    @Environment(\.managedObjectContext) var viewContext
    @State private var itemsToAdd = Set<WatchlistItem>()
    // This allows the SelectedListView to change to the new list when it is created.
    @Binding var newSelectedList: CustomList?
    @State private var searchQuery = String()
    @State private var pinOnHome = false
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                TextField("Description", text: $note)
                
#if os(watchOS) || os(tvOS) || os(macOS)
                createList
#endif
            }
            
            Section { Toggle("Pin", isOn: $pinOnHome) }
            
            NavigationLink("Select Items",
                           destination: NewCustomListItemSelector(itemsToAdd: $itemsToAdd,
                                                                  preSelectedItem: preSelectedItem))
        }
#if os(macOS)
        .onAppear { isPresentingNewList = true }
        .onDisappear { isPresentingNewList = false }
#elseif os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .navigationTitle("New List")
        .toolbar {
#if os(macOS)
            ToolbarItem(placement: .principal) { createList }
            ToolbarItem(placement: .cancellationAction) { cancelButton }
#elseif os(iOS) || os(visionOS)
            createList
#endif
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
        .scrollBounceBehavior(.basedOnSize)
    }
    
    private var createList: some View {
        Button("Create", action: save).disabled(title.isEmpty)
    }
    
    private var cancelButton: some View {
        Button("Cancel") { presentView = false }
    }
    
    private func save() {
        if title.isEmpty { return }
        handleSave()
    }
    
    private func handleSave() {
        let list = PersistenceController.shared.createList(title: title,
                                                           description: note,
                                                           items: itemsToAdd,
                                                           isPin: pinOnHome)
        HapticManager.shared.successHaptic()
        newSelectedList = list
        title = ""
        presentView = false
    }
}

#Preview {
#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        NewCustomListView(presentView: .constant(true), newSelectedList: .constant(nil))
#elseif os(macOS)
        NewCustomListView(isPresentingNewList: .constant(false),
                          presentView: .constant(true),
                          newSelectedList: .constant(nil))
#endif
}

struct NewCustomListItemSelector: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)],
        animation: .default) private var items: FetchedResults<WatchlistItem>
    @Binding var itemsToAdd: Set<WatchlistItem>
    var preSelectedItem: WatchlistItem?
    @State private var query = String()
    @State private var searchItems = [WatchlistItem]()
    var list: CustomList?
    var body: some View {
        Form {
            if !searchItems.isEmpty {
                List(searchItems) { item in
                    NewListItemSelectorRow(item: item, selectedItems: $itemsToAdd)
                        .disabled(item.listsArray.contains(where: { $0 == list}))
                }
            } else {
                List(items) { item in
                    NewListItemSelectorRow(item: item, selectedItems: $itemsToAdd)
                        .disabled(item.listsArray.contains(where: { $0 == list}))
                }
            }
        }
        .onAppear {
            if let preSelectedItem {
                itemsToAdd.insert(preSelectedItem)
            }
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("No Titles", systemImage: "rectangle.stack")
            }
        }
        .task(id: query) {
            await search()
        }
        .navigationTitle("Select Items")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
#else
        .searchable(text: $query)
#endif
        .formStyle(.grouped)
        .scrollBounceBehavior(.basedOnSize)
    }
    
    private func search() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        if query.isEmpty && !searchItems.isEmpty { searchItems = [] }
        if query.isEmpty { return }
        if !searchItems.isEmpty { searchItems.removeAll() }
        searchItems.append(contentsOf: items.filter {
            ($0.itemTitle.localizedStandardContains(query)) as Bool
            || ($0.itemOriginalTitle.localizedStandardContains(query)) as Bool
        })
    }
}
