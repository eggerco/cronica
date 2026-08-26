//
//  CronicaAppEntities.swift
//  Cronica
//

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
import AppIntents
import CronicaCore

enum CronicaMediaTypeOption: String, AppEnum {
    case any
    case movie
    case tvShow

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("Media Type"))

    static var caseDisplayRepresentations: [CronicaMediaTypeOption: DisplayRepresentation] = [
        .any: DisplayRepresentation(title: LocalizedStringResource("Any")),
        .movie: DisplayRepresentation(title: LocalizedStringResource("Movie")),
        .tvShow: DisplayRepresentation(title: LocalizedStringResource("TV Show")),
    ]

    var mediaType: MediaType? {
        switch self {
        case .any: return nil
        case .movie: return .movie
        case .tvShow: return .tvShow
        }
    }
}

struct WatchlistTitleEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("Watchlist Title"))
    static var defaultQuery = WatchlistTitleEntityQuery()

    let id: String
    let title: String
    let mediaLabel: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(mediaLabel)")
    }

    init(item: WatchlistItem) {
        id = item.itemContentID
        title = item.itemTitle
        switch item.itemMedia {
        case .movie:
            mediaLabel = String(localized: "Movie")
        case .tvShow:
            mediaLabel = String(localized: "TV Show")
        case .person:
            mediaLabel = String(localized: "Person")
        }
    }
}

struct WatchlistTitleEntityQuery: EntityQuery {
    func entities(for identifiers: [WatchlistTitleEntity.ID]) async throws -> [WatchlistTitleEntity] {
        let persistence = PersistenceController.shared
        return identifiers.compactMap { id in
            persistence.fetch(for: id).map(WatchlistTitleEntity.init(item:))
        }
    }

    func suggestedEntities() async throws -> [WatchlistTitleEntity] {
        await MainActor.run {
            SiriIntentService.allWatchlistEntities()
        }
    }

    func entities(matching string: String) async throws -> [WatchlistTitleEntity] {
        await MainActor.run {
            SiriIntentService.watchlistEntities(matching: string)
        }
    }
}

struct UpNextEpisodeEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("Up Next Episode"))
    static var defaultQuery = UpNextEpisodeEntityQuery()

    let id: String
    let showTitle: String
    let episodeLabel: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(showTitle)", subtitle: "\(episodeLabel)")
    }

    init(summary: SiriIntentService.UpNextSummary) {
        id = "\(summary.contentID)-\(summary.seasonNumber)-\(summary.episodeNumber)"
        showTitle = summary.showTitle
        if let name = summary.episodeName, !name.isEmpty {
            episodeLabel = name
        } else {
            episodeLabel = String(
                format: String(localized: "S%d · E%d"),
                summary.seasonNumber,
                summary.episodeNumber
            )
        }
    }
}

struct UpNextEpisodeEntityQuery: EntityQuery {
    func entities(for identifiers: [UpNextEpisodeEntity.ID]) async throws -> [UpNextEpisodeEntity] {
        let summaries = try await SiriIntentService.upNextSummaries(limit: 10)
        return summaries
            .map(UpNextEpisodeEntity.init(summary:))
            .filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [UpNextEpisodeEntity] {
        let summaries = try await SiriIntentService.upNextSummaries(limit: 8)
        return summaries.map(UpNextEpisodeEntity.init(summary:))
    }
}

struct SearchResultEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("Search Result"))
    static var defaultQuery = SearchResultEntityQuery()

    let id: String
    let title: String
    let subtitle: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
    }

    init(summary: SiriIntentService.SearchSummary) {
        id = summary.id
        title = summary.title
        subtitle = summary.subtitle
    }

    init(id: String, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

struct SearchResultEntityQuery: EntityStringQuery {
    func entities(for identifiers: [SearchResultEntity.ID]) async throws -> [SearchResultEntity] {
        []
    }

    func entities(matching string: String) async throws -> [SearchResultEntity] {
        let results = try await SiriIntentService.searchTitles(query: string, limit: 8)
        return results.map(SearchResultEntity.init(summary:))
    }

    func suggestedEntities() async throws -> [SearchResultEntity] {
        []
    }
}
#endif
