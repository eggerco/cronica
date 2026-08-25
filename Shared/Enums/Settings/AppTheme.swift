//
//  AppTheme.swift
//  Cronica
//
//  Created by Alexandre Madeira on 03/01/23.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case system, light, dark
    var overrideTheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    var localizableName: String {
        switch self {
        case .system:
            return String(localized: "System")
        case .light:
            return String(localized: "Light")
        case .dark:
            return String(localized: "Dark")
        }
    }
}
