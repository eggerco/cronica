//
//  WatchlistSearchScope.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 16/08/22.
//

import SwiftUI

enum WatchlistSearchScope: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case noScope, movies, shows
    var localizableTitle: String {
        switch self {
        case .noScope: String(localized: "All")
        case .movies: String(localized: "Movies")
        case .shows: String(localized: "Series")
        }
    }
}
