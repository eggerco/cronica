//
//  ConfirmationPopupModifier.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 05/06/22.
//

import SwiftUI

/// Provides system haptic feedback for watchlist and related actions.
/// Visual confirmation comes from control state changes (symbols/buttons), not a custom toast.
struct ConfirmationPopupModifier: ViewModifier {
    @Binding var isShowing: Bool
    var item: ActionPopupItems?
    @State private var feedbackToken = 0

    func body(content: Content) -> some View {
        content
#if os(iOS)
            .sensoryFeedback(.success, trigger: feedbackToken)
#endif
            .onChange(of: isShowing) { _, showing in
                guard showing else { return }
                feedbackToken &+= 1
                isShowing = false
            }
    }
}

enum ActionPopupItems: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case addedWatchlist, removedWatchlist, markedWatched, removedWatched, markedFavorite, removedFavorite,
         markedArchive, removedArchive, markedPin, removedPin, markedEpisodeWatched, removedEpisodeWatched,
         feedbackSent
    
    var localizedString: String {
        switch self {
        case .addedWatchlist: String(localized: "Added")
        case .removedWatchlist: String(localized: "Removed")
        case .markedWatched: String(localized: "Watched")
        case .removedWatched: String(localized: "Unwatched")
        case .markedFavorite: String(localized: "Favorited")
        case .removedFavorite: String(localized: "Unfavorited")
        case .markedArchive: String(localized: "Archived")
        case .removedArchive: String(localized: "Unarchived")
        case .markedPin: String(localized: "Pinned")
        case .removedPin: String(localized: "Unpinned")
        case .markedEpisodeWatched: String(localized: "Watched")
        case .removedEpisodeWatched: String(localized: "Unwatched")
        case .feedbackSent: String(localized: "Feedback sent. Thank you.")
        }
    }
    
    var toSfSymbol: String {
        switch self {
        case .addedWatchlist: "plus.circle.fill"
        case .removedWatchlist: "minus.circle.fill"
        case .markedWatched: "rectangle.badge.checkmark.fill"
        case .removedWatched: "rectangle.badge.checkmark"
        case .markedFavorite: "heart.fill"
        case .removedFavorite: "heart.slash.fill"
        case .markedArchive: "archivebox.fill"
        case .removedArchive: "archivebox"
        case .markedPin: "pin.fill"
        case .removedPin: "pin.slash.fill"
        case .markedEpisodeWatched: "rectangle.badge.checkmark.fill"
        case .removedEpisodeWatched: "rectangle.badge.checkmark"
        case .feedbackSent: "envelope.fill"
        }
    }
}
