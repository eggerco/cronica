//
//  UpNextSortOrder.swift
//  Cronica
//

import Foundation

enum UpNextSortOrder: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case recentActivity, watchProgress

    var localizableName: String {
        switch self {
        case .recentActivity:
            String(localized: "Recent Activity")
        case .watchProgress:
            String(localized: "Watch Progress")
        }
    }
}
