//
//  CronicaAppIntents.swift
//  Cronica
//

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
import AppIntents

struct AddToWatchlistIntent: AppIntent {
    static var title: LocalizedStringResource = "Add to Watchlist"
    static var description = IntentDescription("Add a movie or TV show to your Cronica watchlist.")
    static var openAppWhenRun = false

    @Parameter(title: "Title")
    var title: SearchResultEntity

    @Parameter(title: "Type", default: .any)
    var mediaType: CronicaMediaTypeOption

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) to my watchlist")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let name = try await SiriIntentService.addToWatchlist(
            title: title.title,
            mediaType: mediaType.mediaType
        )
        return .result(dialog: IntentDialog(stringLiteral: String(
            format: String(localized: "Added %@ to your watchlist."),
            name
        )))
    }
}

struct RemoveFromWatchlistIntent: AppIntent {
    static var title: LocalizedStringResource = "Remove from Watchlist"
    static var description = IntentDescription("Remove a title from your Cronica watchlist.")
    static var openAppWhenRun = false

    @Parameter(title: "Title")
    var title: WatchlistTitleEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Remove \(\.$title) from my watchlist")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let name = try await SiriIntentService.removeFromWatchlist(title: title.title)
        return .result(dialog: IntentDialog(stringLiteral: String(
            format: String(localized: "Removed %@ from your watchlist."),
            name
        )))
    }
}

struct MarkTitleWatchedIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark as Watched"
    static var description = IntentDescription("Mark a movie or TV show as watched in Cronica.")
    static var openAppWhenRun = false

    @Parameter(title: "Title")
    var title: SearchResultEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$title) as watched")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let name = try await SiriIntentService.markTitleWatched(title: title.title)
        return .result(dialog: IntentDialog(stringLiteral: String(
            format: String(localized: "Marked %@ as watched."),
            name
        )))
    }
}

struct MarkUpNextEpisodeWatchedIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Up Next as Watched"
    static var description = IntentDescription("Mark your next episode as watched in Cronica.")
    static var openAppWhenRun = false

    static var parameterSummary: some ParameterSummary {
        Summary("Mark my next episode as watched")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let label = try await SiriIntentService.markNextUpNextEpisodeWatched()
        return .result(dialog: IntentDialog(stringLiteral: String(
            format: String(localized: "Marked %@ as watched."),
            label
        )))
    }
}

struct GetUpNextIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Up Next"
    static var description = IntentDescription("See what episodes are up next in Cronica.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<[UpNextEpisodeEntity]> & ProvidesDialog {
        let summaries = try await SiriIntentService.upNextSummaries(limit: 5)
        let entities = summaries.map(UpNextEpisodeEntity.init(summary:))
        let lines = entities.map { "\($0.showTitle): \($0.episodeLabel)" }
        let dialogText = lines.joined(separator: "\n")
        return .result(value: entities, dialog: IntentDialog(stringLiteral: dialogText))
    }
}

struct SearchTitlesIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Titles"
    static var description = IntentDescription("Search for movies and TV shows in Cronica.")
    static var openAppWhenRun = false

    @Parameter(title: "Query")
    var query: SearchResultEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Search for \(\.$query)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[SearchResultEntity]> & ProvidesDialog {
        let results = try await SiriIntentService.searchTitles(query: query.title, limit: 5)
        let entities = results.map(SearchResultEntity.init(summary:))
        let dialogText = entities.map(\.title).joined(separator: ", ")
        return .result(value: entities, dialog: IntentDialog(stringLiteral: dialogText))
    }
}

struct OpenTitleIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Title"
    static var description = IntentDescription("Open a movie or TV show in Cronica.")
    static var openAppWhenRun = true

    @Parameter(title: "Title")
    var title: SearchResultEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$title) in Cronica")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let url = try await SiriIntentService.openURL(for: title.title)
        await SiriDeepLinkBridge.storePending(url)
        return .result(dialog: IntentDialog(stringLiteral: String(
            format: String(localized: "Opening %@ in Cronica."),
            title.title
        )))
    }
}
#endif
