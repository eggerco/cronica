//
//  ConfirmationPopupModifier.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 05/06/22.
//

import SwiftUI

/// Lightweight confirmation banner for watchlist and action feedback.
struct ConfirmationPopupModifier: ViewModifier {
    @Binding var isShowing: Bool
    var item: ActionPopupItems?

    private static let bannerAnimation = Animation.easeInOut(duration: 0.25)

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isShowing, let item {
                    Label(item.localizedString, systemImage: item.toSfSymbol)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
#if !os(watchOS)
                        .background(.regularMaterial, in: Capsule())
#endif
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onTapGesture {
                            withAnimation(Self.bannerAnimation) { isShowing = false }
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation(Self.bannerAnimation) { isShowing = false }
                            }
                        }
#if os(iOS)
                        .sensoryFeedback(.success, trigger: item.id)
#endif
                }
            }
            .animation(Self.bannerAnimation, value: isShowing)
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
