//
//  WatchListSection.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 24/04/22.
//

import SwiftUI

struct WatchListSection: View {
    let items: [WatchlistItem]
    var title: String
    var emptyFilter: SmartFiltersTypes? = nil
    private let context = PersistenceController.shared
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    var body: some View {
        if !items.isEmpty {
#if os(macOS)
            table
#else
            list
#endif
        } else {
            empty
        }
    }
    
    private var table: some View {
        Form {
            list
        }
        .formStyle(.grouped)
    }
    
    private var list: some View {
        List {
            Section {
                ForEach(items) {
                    WatchlistItemRowView(content: $0, showPopup: $showPopup, popupType: $popupType)
                }
                .onDelete(perform: delete)
            } header: {
                HStack {
                    Text(title)
                    Spacer()
                    Text("\(items.count) items")
                }
            } 
        }
    }
    
    @ViewBuilder
    private var empty: some View {
        EmptyListView(filter: emptyFilter)
    }
    
    private func fetchDroppedItems(_ items: [ItemContent]) {
        for item in items {
            Task {
                let result = try? await NetworkService.shared.fetchItem(id: item.id, type: item.itemContentMedia)
                if let result {
                    PersistenceController.shared.save(result)
                }
            }
        }
    }
    
    private func delete(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(context.delete)
        }
    }
}
