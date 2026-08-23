//
//  ReleaseDate.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 26/08/22.
//

import Foundation

public struct ReleaseDates: Codable, Hashable {
    public let results: [ReleaseDatesResult]
}
public struct ReleaseDatesResult: Codable, Hashable {
    public let iso31661: String?
    public let releaseDates: [ReleaseDate]?
}
public struct ReleaseDate: Codable, Hashable {
    public let certification, iso6391, releaseDate: String?
    public let type: Int?
}
