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

    func sortedItems(by order: WatchlistSortOrder, pinnedFirst: Bool = false) -> [WatchlistItem] {
        let ids = itemOrder?.split(separator: ",").map(String.init) ?? []
        let positions = Dictionary(ids.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        return order.sort(itemsSet, pinnedFirst: pinnedFirst) { item in
            item.contentID.flatMap { positions[$0] }
        }
    }

    var itemIDToString: String {
        guard let id else { return String() }
        return id.uuidString
    }
}
