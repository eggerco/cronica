//
//  AddToListRow.swift
//  Cronica
//
//  Created by Alexandre Madeira on 07/05/23.
//

import SwiftUI

struct AddToListRow: View {
    @State private var isItemAdded = false
    var list: CustomList
    @Binding var item: WatchlistItem?
    @Binding var showView: Bool
    @State private var selectionTrigger = 0
    var body: some View {
        Button {
            guard let item else { return }
            PersistenceController.shared.updateList(for: item.itemContentID, to: list)
            withAnimation { isItemAdded.toggle() }
            selectionTrigger &+= 1
        } label: {
            HStack {
                Image(systemName: isItemAdded ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(SettingsStore.shared.appTheme.color)
                    .padding(.leading, 4)
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        Text(list.itemTitle)
                        if list.isPin {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                                .accessibilityLabel(String(localized: "Favorite"))
                        }
                    }
                    if let totalItems = list.items?.count {
                        Text("\(totalItems) items")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else if let notes = list.notes, !notes.isEmpty {
                        Text(notes)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        Text("Last Updated at \(list.itemLastUpdateFormatted)")
                    }
                }
                .padding(.leading, 4)
            }
        }
        .buttonStyle(.plain)
#if os(iOS)
        .sensoryFeedback(.selection, trigger: selectionTrigger) { _, _ in
            SettingsStore.shared.hapticFeedback
        }
#endif
        .onAppear { isItemInList() }
    }
    
    private func isItemInList() {
        if let item {
            if list.itemsSet.contains(item) { isItemAdded.toggle() }
        }
    }
}
