//
//  CustomListView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 22/04/23.
//

import SwiftUI

struct CustomListView: View {
    @Binding var list: CustomList?
	@Binding var sortOrder: WatchlistSortOrder
    @State private var showPopup = false
    @State private var popupType: ActionPopupItems?
	private var sortedItems: [WatchlistItem] {
		list?.sortedItems(by: sortOrder) ?? []
	}
    var body: some View {
        if let list {
            List {
                Section {
                    if list.itemsArray.isEmpty {
                        EmptyListView()
                    } else {
                        ForEach(sortedItems) { item in
                            WatchlistItemRowView(content: item, showPopup: $showPopup, popupType: $popupType)
                        }
                    }
                } header: {
                    Text(list.itemTitle).lineLimit(1)
                }
            }
        } else {
            EmptyListView()
        }
    }
}
