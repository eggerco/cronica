//
//  WatchlistPosterStatusOverlay.swift
//  Cronica
//
//  Minimal bottom-trailing status indicator for explore/search posters.
//

import SwiftUI

/// Subtle SF Symbol status for posters outside the Watchlist tab.
/// Prefer a single symbol with a light shadow — no capsules or stacked icons.
struct WatchlistPosterStatusOverlay: View {
    let isWatched: Bool
    var compact: Bool = false

    private var symbolName: String {
        isWatched ? "checkmark.circle.fill" : "square.stack.fill"
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
                    .font(compact ? .caption.weight(.semibold) : .body.weight(.semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
                    .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
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
