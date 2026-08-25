//
//  ExternalIDFind.swift
//  CronicaCore
//

import Foundation

/// Response from TMDB `/3/find/{external_id}`.
public struct ExternalIDFindResponse: Codable, Sendable, Hashable {
    public let movieResults: [ItemContent]?
    public let tvResults: [ItemContent]?

    public init(movieResults: [ItemContent]?, tvResults: [ItemContent]?) {
        self.movieResults = movieResults
        self.tvResults = tvResults
    }
}

public enum ExternalIDSource: String, Sendable {
    case imdbID = "imdb_id"
}
