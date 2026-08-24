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
            NSLocalizedString("Recent Activity", comment: "Up Next sort order")
        case .watchProgress:
            NSLocalizedString("Watch Progress", comment: "Up Next sort order")
        }
    }
}
