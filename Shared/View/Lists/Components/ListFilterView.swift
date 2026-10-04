//
//  ListFilterView.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 05/02/24.
//

import SwiftUI

struct ListFilterView: View {
    @Binding var showView: Bool
    @Binding var sortOrder: WatchlistSortOrder
    @Binding var filter: SmartFiltersTypes
    @Binding var showAllItems: Bool
    @StateObject private var settings = SettingsStore.shared
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Show All", isOn: $showAllItems)
                } header: {
                    Text("Basic Filter")
                }
                
                Section {
                    Picker("Sort Order",
                           selection: $sortOrder) {
                        ForEach(WatchlistSortOrder.allCases) { item in
                            Text(item.localizableName).tag(item)
                        }
                    }
                    Toggle("Pinned Items on Top", isOn: $settings.showPinnedOnTop)
                }
                
                Section {
                    Picker(selection: $filter) {
                        ForEach(SmartFiltersTypes.allCases) { sort in
                            Text(sort.title).tag(sort)
                        }
                    } label: {
                        EmptyView()
                    }
                    .disabled(showAllItems)
                    .pickerStyle(.inline)
                } header: {
                    Text("Smart Filters")
                } footer: {
                    if showAllItems {
                        Text("Smart Filters only works when 'Show All Items' is disabled.")
                    } else {
                        Text("To Watch is titles you have not started. Watching is shows in progress. Watched is finished.")
                    }
                }
            }
            .navigationTitle("Filters")
#if !os(tvOS) && !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .nativeSheetDismissToolbar { showView = false }
            .cronicaSensoryFeedback(.selection, trigger: filter)
            .cronicaSensoryFeedback(.selection, trigger: sortOrder)
            .cronicaSensoryFeedback(.selection, trigger: showAllItems)
            .cronicaSensoryFeedback(.selection, trigger: settings.showPinnedOnTop)
            .scrollBounceBehavior(.basedOnSize)
            .onChange(of: filter) {
                showView = false
            }
            .onChange(of: sortOrder) {
                showView = false
            }
            .onChange(of: showAllItems) {
                showView = false
            }
        }
#if !os(tvOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .appTint()
        .appTheme()
#endif
    }
}
