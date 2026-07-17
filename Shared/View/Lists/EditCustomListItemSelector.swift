//
//  EditCustomListItemSelector.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 29/10/23.
//

import SwiftUI
import NukeUI

struct EditCustomListItemSelector: View {
    var list: CustomList
    @Binding var itemsToRemove: Set<WatchlistItem>
    @State private var query = String()
    @State private var searchItems = [WatchlistItem]()
    var body: some View {
        Form {
            if !searchItems.isEmpty {
                Section {
                    List {
                        ForEach(searchItems) { item in
                            Button {
                                if itemsToRemove.contains(item) {
                                    itemsToRemove.remove(item)
                                } else {
                                    itemsToRemove.insert(item)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: itemsToRemove.contains(item) ? "minus.circle.fill" : "circle")
                                        .foregroundColor(itemsToRemove.contains(item) ? .red : nil)
                                    LazyImage(url: item.backCompatibleCardImage) { state in
                                        if let image = state.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            ZStack {
                                                Rectangle().fill(.gray.gradient)
                                                Image(systemName: "popcorn.fill")
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                        }
                                    }
                                    .frame(width: 70, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.compact, style: .continuous))
                                    .overlay {
                                        if itemsToRemove.contains(item) {
                                            ZStack {
                                                Rectangle().fill(.black.opacity(0.4))
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.compact, style: .continuous))
                                        }
                                    }
                                    VStack(alignment: .leading) {
                                        Text(item.itemTitle)
                                            .lineLimit(1)
                                            .foregroundColor(itemsToRemove.contains(item) ? .secondary : nil)
                                        Text(item.itemMedia.title)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                Section {
                    List {
                        ForEach(list.itemsArray, id: \.itemContentID) { item in
                            HStack {
                                Image(systemName: itemsToRemove.contains(item) ? "minus.circle.fill" : "circle")
                                    .foregroundColor(itemsToRemove.contains(item) ? .red : nil)
                                LazyImage(url: item.backCompatibleCardImage) { state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        ZStack {
                                            Rectangle().fill(.gray.gradient)
                                            Image(systemName: "popcorn.fill")
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                }
                                .frame(width: 70, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.compact, style: .continuous))
                                .overlay {
                                    if itemsToRemove.contains(item) {
                                        ZStack {
                                            Rectangle().fill(.black.opacity(0.4))
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.compact, style: .continuous))
                                    }
                                }
                                VStack(alignment: .leading) {
                                    Text(item.itemTitle)
                                        .lineLimit(1)
                                        .foregroundColor(itemsToRemove.contains(item) ? .secondary : nil)
                                    Text(item.itemMedia.title)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .onTapGesture {
                                if itemsToRemove.contains(item) {
                                    itemsToRemove.remove(item)
                                } else {
                                    itemsToRemove.insert(item)
                                }
                            }
                        }
                    }
                }
            }
            
        }
        .overlay { if list.itemsArray.isEmpty { Text("Empty") } }
        .task(id: query) {
            await search()
        }
        .navigationTitle("Remove Items")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
#else
        .searchable(text: $query)
#endif
        .formStyle(.grouped)
    }
    
    private func search() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        if query.isEmpty && !searchItems.isEmpty { searchItems = [] }
        if query.isEmpty { return }
        if !searchItems.isEmpty { searchItems.removeAll() }
        searchItems.append(contentsOf: list.itemsArray.filter {
            ($0.itemTitle.localizedStandardContains(query)) as Bool
            || ($0.itemOriginalTitle.localizedStandardContains(query)) as Bool
        })
    }
}
