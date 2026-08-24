//
//  SelectListView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 10/02/23.
//

import SwiftUI

/// This view is responsible for lettings users select which their want to see in WatchlistView.
struct SelectListView: View {
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomList.title, ascending: true)],
        animation: .default)
    private var lists: FetchedResults<CustomList>
    @Binding var selectedList: CustomList?
    @Binding var navigationTitle: String
    @Binding var showListSelection: Bool
    @State private var showAllItems = true
    @State private var listToDelete: CustomList?
#if os(macOS)
    @State private var isCreateNewListPresented = false
#endif
    @State private var isEditing = false
    @State private var query = String()
    @State private var queryResult = [CustomList]()
    @State private var isSearchingLists = false
    var body: some View {
        NavigationStack {
#if os(iOS) || os(tvOS)
            form
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        doneButton
                    }
                    ToolbarItem {
                        newList
                    }
                }
#if os(iOS)
                .searchable(text: $query, placement: .navigationBarDrawer(displayMode: lists.count > 6 ? .always : .automatic))
                .autocorrectionDisabled()
                .task(id: query) {
                    await search()
                }
#endif
                .scrollBounceBehavior(.basedOnSize)
#else
            form
                .formStyle(.grouped)
                .toolbar {
#if !os(visionOS) && !os(macOS)
                    if !isCreateNewListPresented {
                        ToolbarItem(placement: .automatic) {
                            if !lists.isEmpty { newList }
                        }
                    }
#endif
#if os(macOS)
                    ToolbarItem(placement: .automatic) {
                        newList
                            .disabled(isCreateNewListPresented)
                    }
#endif
                    ToolbarItem(placement: .cancellationAction) {
                        doneButton
                    }
                }
#endif
        }
        .confirmationDialog(
            "Are You Sure?",
            isPresented: Binding(
                get: { listToDelete != nil },
                set: { if !$0 { listToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Confirm", role: .destructive) {
                if let listToDelete {
                    deleteList(listToDelete, includingWatchlistItems: false)
                }
            }
            Button("Confirm and Delete Items", role: .destructive) {
                if let listToDelete {
                    deleteList(listToDelete, includingWatchlistItems: true)
                }
            }
            Button("Cancel", role: .cancel) { listToDelete = nil }
        } message: {
            if let listToDelete {
                Text("Delete \(listToDelete.itemTitle)? Items can stay on your watchlist or be removed with the list.")
            }
        }
#if os(iOS)
        .appTint()
        .appTheme()
        .presentationDetents([lists.count > 4 ? .large : .medium])
        .presentationDragIndicator(.visible)
#endif
    }
    
    private var form: some View {
        Form {
            Section {
                List {
                    // default list selector
                    if queryResult.isEmpty && query.isEmpty {
                        Button {
                            selectedList = nil
                            showListSelection.toggle()
                        } label: {
                            DefaultListRow(selectedList: $selectedList)
                        }
                        .buttonStyle(.plain)
                    }
                    // if empty, offers a more visual way to create new list
                    if !lists.isEmpty {
                        if !queryResult.isEmpty {
#if os(iOS)
                            ForEach(queryResult) { item in
                                Button {
                                    selectedList = item
                                    showListSelection = false
                                } label: {
                                    ListRowItem(list: item, selectedList: $selectedList)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: SettingsStore.shared.allowFullSwipe) {
                                    NavigationLink("Edit") {
                                        EditCustomList(list: item, showListSelection: $showListSelection)
                                    }
                                }
                            }
#endif
                        } else if !query.isEmpty && queryResult.isEmpty {
                            if isSearchingLists {
                                ProgressView()
                            } else {
                                CenterHorizontalView {
                                    SearchContentUnavailableView(query: query)
                                }
                            }
                        } else {
                            ForEach(lists) { item in
#if os(tvOS)
                                Button {
                                    selectedList = item
                                    showListSelection.toggle()
                                } label: {
                                    ListRowItem(list: item, selectedList: $selectedList)
                                }
#else
                                Button {
                                    selectedList = item
                                    showListSelection = false
                                } label: {
                                    ListRowItem(list: item, selectedList: $selectedList)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        listToDelete = item
                                    }
                                    NavigationLink {
#if os(iOS)
                                        EditCustomList(list: item, showListSelection: $showListSelection)
#elseif os(macOS)
                                        EditCustomList(isPresentingNewList: $isCreateNewListPresented, list: item, showListSelection: $showListSelection)
#endif
                                    } label: {
                                        Text("Edit")
                                    }
                                }
#if os(iOS) || os(macOS)
                                .swipeActions(edge: .trailing, allowsFullSwipe: SettingsStore.shared.allowFullSwipe) {
                                    NavigationLink {
#if os(iOS)
                                        EditCustomList(list: item, showListSelection: $showListSelection)
#elseif os(macOS)
                                        EditCustomList(isPresentingNewList: $isCreateNewListPresented, list: item, showListSelection: $showListSelection)
#endif
                                    } label: {
                                        Text("Edit")
                                    }
                                }
#endif
#endif
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Your Lists")
                    Spacer()
                }
            }
        }
        .cronicaStandardNavigationDestinations()
    }
    
    private func search() async {
        isSearchingLists = true
        try? await Task.sleep(nanoseconds: 300_000_000)
        if query.isEmpty && !queryResult.isEmpty { queryResult = [] }
        if query.isEmpty { return }
        if !queryResult.isEmpty { queryResult.removeAll() }
        queryResult.append(contentsOf: lists.filter {
            ($0.itemTitle.localizedStandardContains(query.lowercased())) as Bool
        })
        isSearchingLists = false
    }
    
    private var doneButton: some View {
        Button("Done") { showListSelection.toggle() }
    }
    
    private var newList: some View {
        NavigationLink {
#if os(iOS) || os(tvOS)
            NewCustomListView(presentView: $showListSelection, newSelectedList: $selectedList)
#elseif os(macOS)
            NewCustomListView(isPresentingNewList: $isCreateNewListPresented, presentView: $showListSelection, newSelectedList: $selectedList)
#endif
        } label: {
            Label("New List", systemImage: "plus.rectangle.on.rectangle")
#if !os(macOS)
                .labelStyle(.iconOnly)
#endif
        }
    }
    
    private func deleteList(_ list: CustomList, includingWatchlistItems: Bool) {
        if selectedList == list {
            selectedList = nil
            navigationTitle = NSLocalizedString("Watchlist", comment: "")
        }
        PersistenceController.shared.deleteList(list, includingWatchlistItems: includingWatchlistItems)
        listToDelete = nil
    }
    
    private func delete(offsets: IndexSet) {
        withAnimation {
            offsets.map { lists[$0] }.forEach(PersistenceController.shared.delete)
        }
    }
}

#Preview {
    SelectListView(
        selectedList: .constant(
            nil
        ),
        navigationTitle: .constant(
            "Preview"
        ),
        showListSelection: .constant(
            true
        )
    )
}
