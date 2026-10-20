//
//  DefaultListView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 21/04/23.
//

import SwiftUI

struct DefaultListView: View {
    @Binding var selectedOrder: SmartFiltersTypes?
	@Binding var sortOrder: WatchlistSortOrder
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)],
        animation: .default) private var items: FetchedResults<WatchlistItem>
	private var sortedItems: [WatchlistItem] {
		sortOrder.sort(items)
	}
	private var smartFiltersItems: [WatchlistItem] {
		let visible = sortedItems.filter { !$0.hideFromWatchlist }
		let filter = selectedOrder ?? .notWatched
		return visible.filter { filter.matches($0) }
	}
    var body: some View {
        if let selectedOrder {
			List {
				WatchlistSectionView(items: smartFiltersItems,
									 title: selectedOrder.title)
			}
        } else {
            EmptyListView()
        }
    }
}

#Preview {
    DefaultListView(selectedOrder: .constant(.notWatched), sortOrder: .constant(.titleAsc))
}
