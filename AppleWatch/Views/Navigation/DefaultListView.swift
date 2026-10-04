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
		switch selectedOrder {
		case .released:
			return visible.filter { $0.isReleased }
		case .production:
			return visible.filter { $0.isInProduction || $0.isUpcoming }
		case .watching:
			return visible.filter { $0.isCurrentlyWatching }
		case .watched:
			return visible.filter { $0.isWatched }
		case .favorites:
			return visible.filter { $0.isFavorite }
		case .pin:
			return visible.filter { $0.isPin }
		case .archive:
			return visible.filter { $0.isArchive }
		case .notWatched:
			return visible.filter { !$0.isCurrentlyWatching && !$0.isWatched && $0.isReleased }
		case .none:
			return visible.filter { $0.isReleased }
		}
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
    DefaultListView(selectedOrder: .constant(.released), sortOrder: .constant(.titleAsc))
}
