//
//  QuickActionCoordinator.swift
//  Cronica
//

#if os(iOS)
import Combine
import Foundation

enum QuickActionFeedback: Equatable {
    case markedEpisodeWatched
    case noUpNext
}

@MainActor
final class QuickActionCoordinator: ObservableObject {
    static let shared = QuickActionCoordinator()

    @Published private(set) var pending: PendingAppNavigation?
    @Published var feedback: QuickActionFeedback?

    private init() {}

    func deliver(_ action: PendingAppNavigation) {
        stage(action)
        SiriNavigationBridge.storePendingNavigation(action)
        QuickActionDebug.log("deliver \(action.rawValue)")
    }

    /// Updates in-memory pending navigation without writing App Group storage.
    func stage(_ action: PendingAppNavigation) {
        pending = action
    }

    /// Reads in-memory pending navigation, then falls back to persisted App Group state.
    func consumePending() -> PendingAppNavigation? {
        if let pending {
            self.pending = nil
            _ = SiriNavigationBridge.consumePendingNavigation()
            QuickActionDebug.log("consume in-memory pending")
            return pending
        }

        if let persisted = SiriNavigationBridge.consumePendingNavigation() {
            QuickActionDebug.log("consume persisted \(persisted.rawValue)")
            return persisted
        }

        return nil
    }

    func postFeedback(_ value: QuickActionFeedback) {
        feedback = value
    }

    func clearFeedback() {
        feedback = nil
    }
}
#endif
