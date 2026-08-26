//
//  FindByExternalIDResponse.swift
//  CronicaCore
//

import Foundation

struct FindByExternalIDResponse: Decodable {
    let movieResults: [FindMediaResult]?
    let tvResults: [FindMediaResult]?

    enum CodingKeys: String, CodingKey {
        case movieResults = "movie_results"
        case tvResults = "tv_results"
    }
}

struct FindMediaResult: Decodable {
    let id: Int
}

extension SearchItemContent {
    var resolvedMediaType: MediaType? {
        switch mediaType {
        case "movie":
            return .movie
        case "tv":
            return .tvShow
        default:
            return nil
        }
    }

    var resolvedTitle: String? {
        if let title, !title.isEmpty { return title }
        if let name, !name.isEmpty { return name }
        return nil
    }
}
