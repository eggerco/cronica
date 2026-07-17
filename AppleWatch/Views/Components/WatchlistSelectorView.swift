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
            List {
                Section {
                    ForEach(SmartFiltersTypes.allCases) { list in
                        Button {
                            selectedCustomList = nil
                            selectedList = list
                            showView = false
                        } label: {
                            HStack(spacing: CronicaDesign.Spacing.xs) {
                                if selectedList == list {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(SettingsStore.shared.appTheme.color)
                                }
                                Text(list.title)
                                    .font(CronicaDesign.Typography.caption())
                            }
                        }
                    }
                } header: {
                    Text("Smart List Filters")
                        .font(CronicaDesign.Typography.caption())
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                }

                if !lists.isEmpty {
                    Section {
                        ForEach(lists) { list in
                            Button {
                                selectedList = nil
                                selectedCustomList = list
                                showView = false
                            } label: {
                                HStack(spacing: CronicaDesign.Spacing.xs) {
                                    if selectedCustomList == list {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(SettingsStore.shared.appTheme.color)
                                    }
                                    Text(list.itemTitle)
                                        .font(CronicaDesign.Typography.caption())
                                }
                            }
                        }
                    } header: {
                        Text("Your Lists")
                            .font(CronicaDesign.Typography.caption())
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Picker(selection: $sortOrder) {
                        ForEach(WatchlistSortOrder.allCases) { item in
                            Text(item.localizableName).tag(item)
                        }
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Sort Order")
                        .font(CronicaDesign.Typography.caption())
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Lists")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
