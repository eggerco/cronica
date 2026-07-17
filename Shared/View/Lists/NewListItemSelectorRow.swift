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
    var body: some View {
        Button {
            if selectedItems.contains(item) {
                selectedItems.remove(item)
                withAnimation { isSelected = false }
                HapticManager.shared.selectionHaptic()
            } else {
                selectedItems.insert(item)
                withAnimation { isSelected = true }
                HapticManager.shared.selectionHaptic()
            }
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
                .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.compact, style: .continuous))
                .overlay {
                    if isSelected {
                        ZStack {
                            Rectangle().fill(.black.opacity(0.4))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.compact, style: .continuous))
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
