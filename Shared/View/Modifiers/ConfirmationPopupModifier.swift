//
//  ConfirmationPopupModifier.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 05/06/22.
//

import SwiftUI

/// A dialog that displays a message inside a container of the top of the view.
///
/// The user can tap it to dismiss it faster.
struct ConfirmationPopupModifier: ViewModifier {
    @Binding var isShowing: Bool
    var item: ActionPopupItems?
    func body(content: Content) -> some View {
        content
            .overlay {
                if isShowing, let item {
                    HStack {
                        Label(item.localizedString, systemImage: item.toSfSymbol)
                            .font(.body)
                            .fontDesign(.rounded)
                            .padding()
                            
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.snappy) {
                                isShowing = false
                            }
                        }
                    }
#if !os(watchOS)
                    .background { Rectangle().fill(.thickMaterial) }
#endif
                    .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.large, style: .continuous))
                    .shadow(radius: 1)
                    .padding(.bottom)
                    .animation(.snappy, value: isShowing)
                    .onTapGesture { withAnimation { isShowing = false } }
                    .transition(.move(edge: .bottom))
                    .frame (maxHeight: .infinity, alignment: .bottom)
                }
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
