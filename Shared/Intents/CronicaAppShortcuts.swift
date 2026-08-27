//
//  CronicaAppShortcuts.swift
//  Cronica
//

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
import AppIntents

struct CronicaAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor { .blue }

    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddToWatchlistIntent(),
            phrases: [
                "Add \(\.$title) to my watchlist in \(.applicationName)",
                "Add \(\.$title) to \(.applicationName)",
                "\(.applicationName) add \(\.$title)",
            ],
            shortTitle: LocalizedStringResource("Add to Watchlist"),
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: RemoveFromWatchlistIntent(),
            phrases: [
                "Remove \(\.$title) from my watchlist in \(.applicationName)",
                "Remove \(\.$title) from \(.applicationName)",
                "\(.applicationName) remove \(\.$title)",
            ],
            shortTitle: LocalizedStringResource("Remove from Watchlist"),
            systemImageName: "minus.circle"
        )

        AppShortcut(
            intent: MarkTitleWatchedIntent(),
            phrases: [
                "Mark \(\.$title) as watched in \(.applicationName)",
                "I watched \(\.$title) on \(.applicationName)",
                "\(.applicationName) mark \(\.$title) watched",
            ],
            shortTitle: LocalizedStringResource("Mark as Watched"),
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: MarkUpNextEpisodeWatchedIntent(),
            phrases: [
                "Mark my next episode as watched in \(.applicationName)",
                "I finished my next episode on \(.applicationName)",
                "\(.applicationName) mark next episode watched",
            ],
            shortTitle: LocalizedStringResource("Mark Up Next Watched"),
            systemImageName: "play.circle"
        )

        AppShortcut(
            intent: GetUpNextIntent(),
            phrases: [
                "What's up next on \(.applicationName)",
                "What should I watch next on \(.applicationName)",
                "\(.applicationName) up next",
            ],
            shortTitle: LocalizedStringResource("Get Up Next"),
            systemImageName: "text.line.first.and.arrowtriangle.forward"
        )

        AppShortcut(
            intent: OpenSearchIntent(),
            phrases: [
                "Search in \(.applicationName)",
                "Find a title in \(.applicationName)",
                "Open search in \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource("Open Search"),
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: AddFromURLIntent(),
            phrases: [
                "Add this link to \(.applicationName)",
                "Add link to my watchlist in \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource("Add from Link"),
            systemImageName: "link"
        )

        AppShortcut(
            intent: OpenTitleIntent(),
            phrases: [
                "Open \(\.$title) in \(.applicationName)",
                "Show \(\.$title) in \(.applicationName)",
                "\(.applicationName) open \(\.$title)",
            ],
            shortTitle: LocalizedStringResource("Open Title"),
            systemImageName: "arrow.up.forward.app"
        )

        AppShortcut(
            intent: OpenWatchlistIntent(),
            phrases: [
                "Open my watchlist in \(.applicationName)",
                "Show my watchlist in \(.applicationName)",
                "\(.applicationName) watchlist",
            ],
            shortTitle: LocalizedStringResource("Open Watchlist"),
            systemImageName: "rectangle.on.rectangle"
        )

        AppShortcut(
            intent: OpenUpNextIntent(),
            phrases: [
                "Open up next in \(.applicationName)",
                "Show up next in \(.applicationName)",
                "\(.applicationName) open up next",
            ],
            shortTitle: LocalizedStringResource("Open Up Next"),
            systemImageName: "play.tv"
        )
    }
}
#endif
