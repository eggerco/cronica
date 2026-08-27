//
//  QuickActionManager.swift
//  Cronica
//

#if os(iOS)
import CoreData
import SwiftUI
import UIKit
import CronicaCore

enum QuickActionManager {
    static let uiTestLaunchActionKey = "-ui-test-quick-action"
    private static var didApplyUITestLaunchAction = false

    @MainActor
    @discardableResult
    static func handle(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let action = HomeScreenQuickAction(shortcutType: shortcutItem.type) else {
            QuickActionDebug.log("unknown shortcut type: \(shortcutItem.type)")
            return false
        }
        QuickActionCoordinator.shared.deliver(action.pendingNavigation)
        return true
    }

    @MainActor
    static func applyUITestLaunchActionIfNeeded() {
        guard UITestingConfiguration.isUITesting, !didApplyUITestLaunchAction else { return }
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: uiTestLaunchActionKey),
              index + 1 < arguments.count,
              let action = PendingAppNavigation(rawValue: arguments[index + 1])
        else { return }

        didApplyUITestLaunchAction = true
        QuickActionDebug.log("UI test launch action \(action.rawValue)")
        QuickActionCoordinator.shared.deliver(action)
    }

    @MainActor
    static func refreshShortcuts() {
        var items = [UIApplicationShortcutItem]()
        if let dynamic = makeMarkUpNextShortcut() {
            items.append(dynamic)
        }
        items.append(contentsOf: staticShortcuts)
        UIApplication.shared.shortcutItems = items
    }

    @MainActor
    static func performMarkUpNextEpisodeWatched() async {
#if canImport(AppIntents)
        do {
            _ = try await SiriIntentService.markNextUpNextEpisodeWatched()
            QuickActionCoordinator.shared.postFeedback(.markedEpisodeWatched)
            if SettingsStore.shared.hapticFeedback {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            refreshShortcuts()
        } catch {
            QuickActionCoordinator.shared.postFeedback(.noUpNext)
            if SettingsStore.shared.hapticFeedback {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            QuickActionDebug.log("mark up next failed: \(error.localizedDescription)")
        }
#endif
    }

    private static var staticShortcuts: [UIApplicationShortcutItem] {
        [
            UIApplicationShortcutItem(
                type: HomeScreenQuickAction.search.rawValue,
                localizedTitle: String(localized: "Search"),
                localizedSubtitle: String(localized: "Find movies and TV shows."),
                icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass")
            ),
            UIApplicationShortcutItem(
                type: HomeScreenQuickAction.watchlist.rawValue,
                localizedTitle: String(localized: "Watchlist"),
                localizedSubtitle: String(localized: "Open your saved titles."),
                icon: UIApplicationShortcutIcon(systemImageName: "rectangle.on.rectangle")
            ),
            UIApplicationShortcutItem(
                type: HomeScreenQuickAction.upNext.rawValue,
                localizedTitle: String(localized: "Up Next"),
                localizedSubtitle: String(localized: "See what's up next."),
                icon: UIApplicationShortcutIcon(systemImageName: "play.tv")
            ),
        ]
    }

    private static func makeMarkUpNextShortcut() -> UIApplicationShortcutItem? {
        guard firstUpNextShowTitle() != nil else { return nil }

        return UIApplicationShortcutItem(
            type: HomeScreenQuickAction.markUpNextEpisode.rawValue,
            localizedTitle: String(localized: "Mark Next Episode Watched"),
            localizedSubtitle: firstUpNextShowTitle(),
            icon: UIApplicationShortcutIcon(systemImageName: "checkmark.rectangle")
        )
    }

    private static func firstUpNextShowTitle() -> String? {
        let context = PersistenceController.shared.container.viewContext
        let request = WatchlistItem.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "displayOnUpNext == %d", true),
            NSPredicate(format: "hideFromUpNext == %d", false),
            NSPredicate(format: "isArchive == %d", false),
            NSPredicate(format: "watched == %d", false),
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)]
        request.fetchLimit = 1
        return try? context.fetch(request).first?.itemTitle
    }
}
#endif
