//
//  NewListItemSelectorRow.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 03/05/23.
//

import SwiftUI
import NukeUI

struct NewListItemSelectorRow: View {
    let item: WatchlistItem
    @State private var isSelected = false
    @Binding var selectedItems: Set<WatchlistItem>
    @State private var selectionTrigger = 0
    var body: some View {
        Button {
            if selectedItems.contains(item) {
                selectedItems.remove(item)
                withAnimation { isSelected = false }
            } else {
                selectedItems.insert(item)
                withAnimation { isSelected = true }
            }
            selectionTrigger &+= 1
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? SettingsStore.shared.appTheme.color : nil)
                    .imageScale(.medium)
                    .padding(.trailing, 4)
                LazyImage(url: item.backCompatibleCardImage) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Rectangle().fill(.gray.gradient)
                            Image(systemName: "popcorn.fill")
                        }
                    }
                }
                .frame(width: 70, height: 50)
                .cornerRadius(8)
                .overlay {
                    if isSelected {
                        ZStack {
                            Rectangle().fill(.black.opacity(0.4))
                        }
                        .cornerRadius(8)
                    }
                }
                .padding(.trailing, 4)
                VStack(alignment: .leading) {
                    Text(item.itemTitle)
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .secondary : nil)
                    Text(item.itemMedia.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
#if os(iOS)
        .sensoryFeedback(.selection, trigger: selectionTrigger) { _, _ in
            SettingsStore.shared.hapticFeedback
        }
#endif
        .task {
            if !isSelected && selectedItems.contains(item) {
                withAnimation { isSelected = true }
            }
        }
    }
}

#Preview {
    NewListItemSelectorRow(item: .example, selectedItems: .constant(Set<WatchlistItem>()))
}
