//
//  SettingsScreens.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 08/04/23.
//

import Foundation

enum SettingsScreens: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case about, appearance, behavior, developer, notifications, tipJar, settings, feedback, region, watchlist, season
}
