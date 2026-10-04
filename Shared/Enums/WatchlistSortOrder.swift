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
    case dateAddedAsc, dateAddedDesc

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
        }
    }

    /// Sorts items in this order. When `pinnedFirst` is set, pinned items keep this order but come first.
    func sort(_ items: some Sequence<WatchlistItem>, pinnedFirst: Bool = false) -> [WatchlistItem] {
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
        }
        guard pinnedFirst else { return sorted }
        return sorted.filter(\.isPin) + sorted.filter { !$0.isPin }
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
