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
		switch sortOrder {
		case .titleAsc:
			return list?.itemsArray.sorted { $0.itemTitle < $1.itemTitle } ?? []
		case .titleDesc:
			return list?.itemsArray.sorted { $0.itemTitle > $1.itemTitle } ?? []
		case .ratingAsc:
			return list?.itemsArray.sorted { $0.userRating < $1.userRating } ?? []
		case .ratingDesc:
			return list?.itemsArray.sorted { $0.userRating > $1.userRating } ?? []
		case .dateAsc:
			return list?.itemsArray.sorted { $0.itemSortDate < $1.itemSortDate } ?? []
		case .dateDesc:
			return list?.itemsArray.sorted { $0.itemSortDate > $1.itemSortDate } ?? []
		case .watchedDateAsc:
			return list?.sortedItems(by: .watchedDateAsc) ?? []
		case .watchedDateDesc:
			return list?.sortedItems(by: .watchedDateDesc) ?? []
		}
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
