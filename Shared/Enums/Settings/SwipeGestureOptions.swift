//
//  SwipeGestureOptions.swift
//  Cronica
//
//  Created by Alexandre Madeira on 03/02/23.
//

import Foundation

enum SwipeGestureOptions: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case markWatch, markFavorite, markPin, markArchive, delete, share
    var localizableName: String {
        switch self {
        case .markWatch: String(localized: "Watch")
        case .markFavorite: String(localized: "Favorite")
        case .markPin: String(localized: "Pin")
        case .markArchive: String(localized: "Archive")
        case .delete: String(localized: "Remove")
        case .share: String(localized: "Share")
        }
    }
}


