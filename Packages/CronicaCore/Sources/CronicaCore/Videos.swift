//
//  Videos.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 28/04/22.
//  swiftlint:disable identifier_name

import Foundation
import SwiftUI

public struct Videos: Codable, Hashable {
    public let results: [VideosResult]
}
public struct VideosResult: Codable, Hashable {
    public let iso639_1, iso3166_1, id, site: String?
    public let name, key, type: String
    public let official: Bool
}
/// A model that represents a trailer.
public struct VideoItem: Identifiable, Codable, Hashable {
    public var id = UUID()
    public let url: URL?
    public let thumbnail: URL?
    public let title: String
    public let videoID: String
}
public extension VideosResult {
    private var isYouTube: Bool {
        if let site {
            if site.lowercased() == "youtube" { return true }
        }
        return false
    }
    var isTrailer: Bool {
        if official {
            if type.lowercased() == "trailer" {
                return isYouTube
            }
        }
        return false
    }
}
