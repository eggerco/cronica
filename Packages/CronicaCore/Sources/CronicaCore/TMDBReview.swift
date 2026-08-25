//
//  TMDBReview.swift
//  CronicaCore
//

import Foundation

public struct TMDBReviewsResponse: Codable, Sendable {
    public let id: Int
    public let page: Int
    public let results: [TMDBReview]
    public let totalPages: Int
    public let totalResults: Int
}

public struct TMDBReview: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let author: String
    public let content: String
    public let createdAt: String?
    public let updatedAt: String?
    public let url: String?
    public let authorDetails: TMDBReviewAuthorDetails?

    public var displayName: String {
        let name = authorDetails?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !name.isEmpty { return name }
        let username = authorDetails?.username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !username.isEmpty { return username }
        return author
    }

    public var ratingLabel: String? {
        guard let rating = authorDetails?.rating else { return nil }
        return String(format: "%.1f/10", rating)
    }
}

public struct TMDBReviewAuthorDetails: Codable, Hashable, Sendable {
    public let name: String?
    public let username: String?
    public let avatarPath: String?
    public let rating: Double?
}

public extension TMDBReview {
    var avatarURL: URL? {
        guard let avatarPath, !avatarPath.isEmpty else { return nil }
        if avatarPath.hasPrefix("http") {
            return URL(string: avatarPath)
        }
        if avatarPath.hasPrefix("/http") {
            return URL(string: String(avatarPath.dropFirst()))
        }
        return NetworkService.urlBuilder(size: .w185, path: avatarPath)
    }
}

public extension Array where Element == TMDBReview {
    var averageRating: Double? {
        let ratings = compactMap(\.authorDetails?.rating)
        guard !ratings.isEmpty else { return nil }
        return ratings.reduce(0, +) / Double(ratings.count)
    }

    var averageRatingLabel: String? {
        guard let averageRating else { return nil }
        return String(format: "%.1f/10", averageRating)
    }
}
