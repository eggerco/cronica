//
//  CronicaWatchlistWidget.swift
//  CronicaWidget
//

import WidgetKit
import SwiftUI
import CronicaCore
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS) || os(macOS)
struct CronicaWatchlistWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WidgetSnapshotEntry

    var body: some View {
        Group {
#if os(iOS)
            switch family {
            case .accessoryInline, .accessoryRectangular, .accessoryCircular:
                WidgetSnapshotLockScreenView(items: entry.items, emptyMessage: entry.emptyMessage)
            default:
                WidgetSnapshotHomeView(items: entry.items, emptyMessage: entry.emptyMessage)
            }
#else
            WidgetSnapshotHomeView(items: entry.items, emptyMessage: entry.emptyMessage)
#endif
        }
        .containerBackground(for: .widget) {
            widgetBackgroundColor
        }
    }

    private var widgetBackgroundColor: Color {
#if os(iOS)
        Color(uiColor: .systemBackground)
#elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
#else
        Color.clear
#endif
    }
}

struct CronicaWatchlistWidget: Widget {
    let kind: String = WidgetKind.watchlist

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: watchlistProvider) { entry in
            CronicaWatchlistWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Watchlist"))
        .description(String(localized: "Pinned and in-progress titles from your watchlist."))
        .supportedFamilies(CronicaWidgetFamilies.watchlistFamilies)
    }

    private var watchlistProvider: WidgetSnapshotProvider {
        WidgetSnapshotProvider(
            emptyMessage: String(localized: "Pin titles or start watching to see them here."),
            readSnapshot: {
                WidgetSnapshotStore.readWatchlist()?.items ?? []
            }
        )
    }
}
#endif
