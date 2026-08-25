//
//  ContentRatings.swift
//  CronicaCore
//

import Foundation

public struct ContentRatings: Codable, Hashable, Sendable {
    public let results: [ContentRatingResult]?

    public init(results: [ContentRatingResult]?) {
        self.results = results
    }
}

public struct ContentRatingResult: Codable, Hashable, Sendable {
    public let iso31661: String?
    public let rating: String?

    public init(iso31661: String?, rating: String?) {
        self.iso31661 = iso31661
        self.rating = rating
    }
}
