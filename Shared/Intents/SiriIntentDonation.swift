//
//  SiriIntentDonation.swift
//  Cronica
//

import CronicaCore

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
import AppIntents

@MainActor
enum SiriIntentDonation {
    static func donateAddedToWatchlist(_ content: ItemContent) async {
        let intent = AddToWatchlistIntent()
        let subtitle: String
        switch content.itemContentMedia {
        case .movie: subtitle = String(localized: "Movie")
        case .tvShow: subtitle = String(localized: "TV Show")
        case .person: subtitle = String(localized: "Person")
        }
        intent.title = SearchResultEntity(
            id: content.itemContentID,
            title: content.itemTitle,
            subtitle: subtitle
        )
        switch content.itemContentMedia {
        case .movie: intent.mediaType = .movie
        case .tvShow: intent.mediaType = .tvShow
        case .person: intent.mediaType = .any
        }
        _ = try? await intent.donate()
    }

    static func donateMarkedWatched(title: String, contentID: String, media: MediaType) async {
        let intent = MarkTitleWatchedIntent()
        let subtitle: String
        switch media {
        case .movie: subtitle = String(localized: "Movie")
        case .tvShow: subtitle = String(localized: "TV Show")
        case .person: subtitle = String(localized: "Person")
        }
        intent.title = SearchResultEntity(id: contentID, title: title, subtitle: subtitle)
        _ = try? await intent.donate()
    }

    static func donateMarkedUpNextEpisode() async {
        _ = try? await MarkUpNextEpisodeWatchedIntent().donate()
    }

    static func donateOpenedWatchlist() async {
        _ = try? await OpenWatchlistIntent().donate()
    }

    static func donateOpenedUpNext() async {
        _ = try? await OpenUpNextIntent().donate()
    }
}
#endif
