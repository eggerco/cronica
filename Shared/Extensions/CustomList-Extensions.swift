//
//  CustomList-Extensions.swift
//  Cronica
//
//  Created by Alexandre Madeira on 13/02/23.
//

import Foundation

extension CustomList {
    var itemTitle: String {
        return title ?? String(localized: "Untitled List")
    }
    var itemLastUpdateFormatted: String {
        if let updatedDate {
            return updatedDate.convertDateToString()
        }
        return String()
    }
    var itemFooter: String {
        if let notes {
            if !notes.isEmpty {
                return notes
            }
        }
        return itemLastUpdateFormatted
    }
    var itemsSet: Set<WatchlistItem> {
        return items as? Set<WatchlistItem> ?? []
    }
    var itemsArray: [WatchlistItem] {
        sortedItems(by: .titleAsc)
    }

    func sortedItems(by order: WatchlistSortOrder) -> [WatchlistItem] {
        let set = items as? Set<WatchlistItem> ?? []
        switch order {
        case .titleAsc:
            return set.sorted { $0.itemTitle < $1.itemTitle }
        case .titleDesc:
            return set.sorted { $0.itemTitle > $1.itemTitle }
        case .ratingAsc:
            return set.sorted { $0.userRating < $1.userRating }
        case .ratingDesc:
            return set.sorted { $0.userRating > $1.userRating }
        case .dateAsc:
            return set.sorted { $0.itemSortDate < $1.itemSortDate }
        case .dateDesc:
            return set.sorted { $0.itemSortDate > $1.itemSortDate }
        }
    }

    var itemIDToString: String {
        guard let id else { return String() }
        return id.uuidString
    }
}
