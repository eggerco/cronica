//
//  WatchlistSelectorView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 21/04/23.
//

import SwiftUI

struct WatchlistSelectorView: View {
    @Binding var showView: Bool
    @Binding var selectedList: SmartFiltersTypes?
    @Binding var selectedCustomList: CustomList?
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomList.title, ascending: true)],
        animation: .default)
    private var lists: FetchedResults<CustomList>
    @State private var item: WatchlistItem?
    @Binding var sortOrder: WatchlistSortOrder
    var body: some View {
        NavigationStack {
            Form {
                List {
                    Section {
                        ForEach(SmartFiltersTypes.allCases) { list in
                            Button {
                                selectedCustomList = nil
                                selectedList = list
                                showView = false
                            } label: {
                                HStack {
                                    if selectedList == list {
                                        Image(systemName: "checkmark.circle")
                                    }
                                    Text(list.title)
                                }
                            }
                        }
                    } header: {
                        Text("Smart List Filters")
                    }
                    
                    if !lists.isEmpty {
                        Section {
                            ForEach(lists) { list in
                                Button {
                                    selectedList = nil
                                    selectedCustomList = list
                                    showView = false
                                } label: {
                                    HStack {
                                        if selectedCustomList == list {
                                            Image(systemName: "checkmark.circle")
                                        }
                                        Text(list.itemTitle)
                                    }
                                }
                            }
                        } header: {
                            Text("Your Lists")
                        }
                    }
                    
                    Section("Sort Order") {
                        Picker(selection: $sortOrder) {
                            ForEach(WatchlistSortOrder.allCases) { item in
                                Text(item.localizableName).tag(item)
                            }
                        } label: {
                            EmptyView()
                        }
                        .pickerStyle(.inline)
                    }
                }
            }
        }
    }
}
