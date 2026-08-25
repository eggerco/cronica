//
//  WatchlistSortOrder.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 05/02/24.
//

import Foundation

enum WatchlistSortOrder: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case titleAsc, titleDesc, dateAsc, dateDesc, ratingAsc, ratingDesc
    
    var localizableName: String {
        switch self {
        case .titleAsc: String(localized: "Title (Asc)")
        case .titleDesc: String(localized: "Title (Desc)")
        case .dateAsc: String(localized: "Date (Asc)")
        case .dateDesc: String(localized: "Date (Desc)")
        case .ratingAsc: String(localized: "Rating (Asc)")
        case .ratingDesc: String(localized: "Rating (Desc)")
        }
    }
}
