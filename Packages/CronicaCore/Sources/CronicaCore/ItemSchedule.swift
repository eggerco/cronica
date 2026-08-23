//
//  ItemSchedule.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 28/04/22.
//

import Foundation

/// The value for the types of schedule supported by ItemContent and WatchlistItem.
///
/// This value is most used to quickly filter out WatchlistItem and handle better fetching in notifications.
public enum ItemSchedule: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    case soon, released, production, cancelled, unknown, renewed, ended
    public var toInt: Int16 {
        switch self {
        case .soon: 0
        case .released: 1
        case .production: 2
        case .cancelled: 3
        case .unknown: 4
        case .renewed: 5
        case .ended: 6
        }
    }
    public var localizedTitle: String {
        switch self {
        case .soon: String(localized: "Coming Soon")
        case .released: String(localized: "Released")
        case .production: String(localized: "Production")
        case .cancelled: String(localized: "Cancelled")
        case .unknown: String(localized: "Unknown")
        case .renewed: String(localized: "Renewed Series")
        case .ended: String(localized: "Ended Series")
        }
    }
}
