//
//  WidgetSnapshot.swift
//  CronicaCore
//

import Foundation

public struct WidgetSnapshotItem: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let deepLink: String
    public let posterFileName: String?
    public let watchProgress: Double
    public let sortDate: Date

    public init(
        id: String,
        title: String,
        subtitle: String?,
        deepLink: String,
        posterFileName: String?,
        watchProgress: Double,
        sortDate: Date
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.deepLink = deepLink
        self.posterFileName = posterFileName
        self.watchProgress = watchProgress
        self.sortDate = sortDate
    }
}

public struct WidgetUpNextSnapshot: Codable, Sendable {
    public let items: [WidgetSnapshotItem]
    public let updatedAt: Date

    public init(items: [WidgetSnapshotItem], updatedAt: Date) {
        self.items = items
        self.updatedAt = updatedAt
    }
}

public struct WidgetWatchlistSnapshot: Codable, Sendable {
    public let items: [WidgetSnapshotItem]
    public let updatedAt: Date

    public init(items: [WidgetSnapshotItem], updatedAt: Date) {
        self.items = items
        self.updatedAt = updatedAt
    }
}

public enum WidgetSnapshotLayout {
    public static let maxItems = 12
    public static let posterJPEGQuality = 0.72
}
