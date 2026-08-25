//
//  WatchlistPosterStatusOverlay.swift
//  Cronica
//
//  Minimal bottom-trailing status indicator for explore/search posters.
//

import SwiftUI

/// Subtle SF Symbol status for posters outside the Watchlist tab.
/// Prefer a single symbol in a padded material circle — no capsules or stacked icons.
struct WatchlistPosterStatusOverlay: View {
    let isWatched: Bool
    var compact: Bool = false

    private var symbolName: String {
        isWatched ? "checkmark" : "square.stack.fill"
    }

    private var accessibilityLabel: String {
        isWatched
            ? String(localized: "Watched")
            : String(localized: "In Watchlist")
    }

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            HStack {
                Spacer(minLength: 0)
                Image(systemName: symbolName)
                    .font(compact ? .caption2.weight(.bold) : .caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(compact ? 5 : 6)
                    .background(.ultraThinMaterial, in: Circle())
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
        WatchlistPosterStatusOverlay(isWatched: true)
            .frame(width: 160, height: 240)
    }
}
