//
//  WatchlistSortOrder.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 05/02/24.
//

import Foundation

enum WatchlistSortOrder: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case titleAsc, titleDesc, dateAsc, dateDesc, watchedDateAsc, watchedDateDesc, ratingAsc, ratingDesc
    case dateAddedAsc, dateAddedDesc, manual

    var localizableName: String {
        switch self {
        case .titleAsc: String(localized: "Title (Asc)")
        case .titleDesc: String(localized: "Title (Desc)")
        case .dateAsc: String(localized: "Release Date (Asc)")
        case .dateDesc: String(localized: "Release Date (Desc)")
        case .watchedDateAsc: String(localized: "Watched Date (Asc)")
        case .watchedDateDesc: String(localized: "Watched Date (Desc)")
        case .ratingAsc: String(localized: "Rating (Asc)")
        case .ratingDesc: String(localized: "Rating (Desc)")
        case .dateAddedAsc: String(localized: "Date Added (Asc)")
        case .dateAddedDesc: String(localized: "Date Added (Desc)")
        case .manual: String(localized: "Manual Order")
        }
    }

    /// Sorts items in this order. When `pinnedFirst` is set, pinned items keep this order but come first.
    /// - Parameter manualRank: position of an item in `.manual` order, nil when it was never placed.
    ///   Defaults to the watchlist's own order (`WatchlistItem.manualOrder`).
    func sort(_ items: some Sequence<WatchlistItem>,
              pinnedFirst: Bool = false,
              manualRank: ((WatchlistItem) -> Int?)? = nil) -> [WatchlistItem] {
        let sorted: [WatchlistItem]
        switch self {
        case .titleAsc:
            sorted = items.sorted { $0.itemTitle < $1.itemTitle }
        case .titleDesc:
            sorted = items.sorted { $0.itemTitle > $1.itemTitle }
        case .ratingAsc:
            sorted = items.sorted { $0.userRating < $1.userRating }
        case .ratingDesc:
            sorted = items.sorted { $0.userRating > $1.userRating }
        case .dateAsc:
            sorted = items.sorted { $0.itemSortDate < $1.itemSortDate }
        case .dateDesc:
            sorted = items.sorted { $0.itemSortDate > $1.itemSortDate }
        case .watchedDateAsc:
            sorted = items.sorted { ($0.watchedDate ?? .distantPast) < ($1.watchedDate ?? .distantPast) }
        case .watchedDateDesc:
            sorted = items.sorted { ($0.watchedDate ?? .distantPast) > ($1.watchedDate ?? .distantPast) }
        case .dateAddedAsc:
            sorted = items.sorted { Self.addedBefore($0, $1, ascending: true) }
        case .dateAddedDesc:
            sorted = items.sorted { Self.addedBefore($0, $1, ascending: false) }
        case .manual:
            let defaultRank: (WatchlistItem) -> Int? = { $0.manualOrder > 0 ? Int($0.manualOrder) : nil }
            let rank = manualRank ?? defaultRank
            sorted = items.sorted { Self.rankedBefore($0, $1, rank: rank) }
        }
        guard pinnedFirst else { return sorted }
        return sorted.filter(\.isPin) + sorted.filter { !$0.isPin }
    }

    /// Rebuilds a full order after `subset` (the visible items) was reordered: visible items take
    /// their former slots in the new order, items hidden by filters keep their place.
    static func merge<Item: AnyObject>(_ subset: [Item], into full: [Item]) -> [Item] {
        let moved = Set(subset.map(ObjectIdentifier.init))
        var reordered = subset.makeIterator()
        let merged = full.map { moved.contains(ObjectIdentifier($0)) ? (reordered.next() ?? $0) : $0 }
        let placed = Set(merged.map(ObjectIdentifier.init))
        return merged + subset.filter { !placed.contains(ObjectIdentifier($0)) }
    }

    /// Items never placed by hand (no rank) go after placed ones, by title.
    private static func rankedBefore(_ lhs: WatchlistItem, _ rhs: WatchlistItem,
                                     rank: (WatchlistItem) -> Int?) -> Bool {
        switch (rank(lhs), rank(rhs)) {
        case let (left?, right?):
            return left < right
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (nil, nil):
            return lhs.itemTitle < rhs.itemTitle
        }
    }

    /// Items saved before the date was recorded have no `dateAdded`: they go last, by title.
    private static func addedBefore(_ lhs: WatchlistItem, _ rhs: WatchlistItem, ascending: Bool) -> Bool {
        switch (lhs.dateAdded, rhs.dateAdded) {
        case let (left?, right?):
            return ascending ? left < right : left > right
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (nil, nil):
            return lhs.itemTitle < rhs.itemTitle
        }
    }
}
