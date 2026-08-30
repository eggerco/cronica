//
//  WidgetAppGroup.swift
//  CronicaCore
//

import Foundation

public enum WidgetAppGroup {
    public static let identifier = "group.cronica"

    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

public enum WidgetKind {
    public static let trending = "CronicaWidget"
    public static let upNext = "CronicaUpNextWidget"
    public static let watchlist = "CronicaWatchlistWidget"
}
