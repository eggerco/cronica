//
//  SectionDetailsPreferredStyle.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 07/04/23.
//

import Foundation

enum SectionDetailsPreferredStyle: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case list, card, poster
    
    var title: String {
        switch self {
        case .list: return String(localized: "List")
        case .card: return String(localized: "Card")
        case .poster: return String(localized: "Poster")
        }
    }
}
enum UpNextDetailsPreferredStyle: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case list, card
    
    var title: String {
        switch self {
        case .list: return String(localized: "List")
        case .card: return String(localized: "Card")
        }
    }
}
