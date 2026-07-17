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
    @Binding var mediaFilter: MediaTypeFilters
    @Binding var showAllItems: Bool
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Show All", isOn: $showAllItems)
                    
                    Picker("Media Type", selection: $mediaFilter) {
                        ForEach(MediaTypeFilters.allCases) { sort in
                            Text(sort.localizableTitle).tag(sort)
                        }
                    }
                    .disabled(!showAllItems)
                } header: {
                    Text("Basic Filter")
                }
                
                Picker("Sort Order",
                       selection: $sortOrder) {
                    ForEach(WatchlistSortOrder.allCases) { item in
                        Text(item.localizableName).tag(item)
                    }
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
                    }
                }
            }
            .navigationTitle("Filters")
#if !os(tvOS) && !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
#if !os(macOS)
                ToolbarItem(placement: .topBarLeading) {
                    RoundedCloseButton { showView = false  }
                }
#endif
            }
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
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(CronicaDesign.Radius.media)
        .presentationDragIndicator(.visible)
        .appTint()
        .appTheme()
#endif
    }
}
