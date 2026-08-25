//
//  WatchlistPosterStatusOverlay.swift
//  Cronica
//
//  Centered status indicator for explore/search posters —
//  same treatment as Watchlist list thumbnails (dim + icon in the middle).
//

import SwiftUI

/// Full-bleed dim with a centered SF Symbol, matching `WatchlistItemRowView` /
/// `ItemContentRowView` watched thumbnails. Used on Discover/Search posters
/// (not Watchlist poster grids, which intentionally show no badge).
struct WatchlistPosterStatusOverlay: View {
    let isWatched: Bool
    var compact: Bool = false

    private var symbolName: String {
        isWatched ? "rectangle.fill.badge.checkmark" : "square.stack.fill"
    }

    private var accessibilityLabel: String {
        isWatched
            ? String(localized: "Watched")
            : String(localized: "In Watchlist")
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
            Image(systemName: symbolName)
                .font(compact ? .body.weight(.semibold) : .title2.weight(.semibold))
                .foregroundStyle(.white)
                .accessibilityLabel(accessibilityLabel)
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
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
