//
//  WatchlistPosterStatusOverlay.swift
//  Cronica
//
//  Compact bottom-trailing status badge for poster/card grids.
//

import SwiftUI

/// Single primary status indicator for explore/search/watchlist posters.
/// Avoids stacking watched + watchlist icons in a crowded gradient strip.
struct WatchlistPosterStatusOverlay: View {
    let isWatched: Bool
    var isFavorite: Bool = false
    var compact: Bool = false

    private var symbolName: String {
        if isWatched {
            return "rectangle.badge.checkmark.fill"
        }
        if isFavorite {
            return "heart.fill"
        }
        return "square.stack.fill"
    }

    private var accessibilityLabel: String {
        if isWatched {
            return String(localized: "Watched")
        }
        if isFavorite {
            return String(localized: "Favorite")
        }
        return String(localized: "In Watchlist")
    }

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            HStack {
                Spacer(minLength: 0)
                Image(systemName: symbolName)
                    .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, compact ? 6 : 8)
                    .padding(.vertical, compact ? 4 : 6)
                    .background(.black.opacity(0.55), in: Capsule())
                    .accessibilityLabel(accessibilityLabel)
                    .padding(compact ? 6 : 8)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.gray.gradient)
            .frame(width: 160, height: 240)
        WatchlistPosterStatusOverlay(isWatched: true, isFavorite: false)
            .frame(width: 160, height: 240)
    }
}
