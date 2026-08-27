//
//  ExtensionAppIntents.swift
//  Cronica
//
//  App Intents compiled into the main app and widget extension for Control Center + interactive widgets.
//

#if canImport(AppIntents) && os(iOS)
import AppIntents

struct OpenUpNextControlIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Up Next"
    static var description = IntentDescription("Open your Up Next list in Cronica.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            SiriNavigationBridge.publishPendingNavigation(.upNext)
        }
        return .result()
    }
}

struct OpenWatchlistControlIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Watchlist"
    static var description = IntentDescription("Open your watchlist in Cronica.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            SiriNavigationBridge.publishPendingNavigation(.watchlist)
        }
        return .result()
    }
}

struct MarkNextUpNextControlIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Up Next Watched"
    static var description = IntentDescription("Mark your next episode as watched in Cronica.")

#if CRONICA_WIDGET_EXTENSION
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            SiriNavigationBridge.storePendingNavigation(.markUpNextEpisode)
        }
        return .result()
    }
#else
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let label = try await UpNextMarkActionRunner.markNextEpisodeWatched()
        return .result(dialog: IntentDialog("Marked \(label) as watched."))
    }
#endif
}
#endif
