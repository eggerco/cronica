//
//  CronicaUpNextWidget.swift
//  CronicaWidget
//

import WidgetKit
import SwiftUI
import CronicaCore
#if os(iOS)
import UIKit
#endif

#if os(iOS)
struct CronicaUpNextWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WidgetSnapshotEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryInline, .accessoryRectangular, .accessoryCircular:
                WidgetSnapshotLockScreenView(items: entry.items, emptyMessage: entry.emptyMessage)
            default:
                WidgetSnapshotHomeView(items: entry.items, emptyMessage: entry.emptyMessage)
            }
        }
        .containerBackground(for: .widget) {
            Color(uiColor: .systemBackground)
        }
    }
}

struct CronicaUpNextWidget: Widget {
    let kind: String = WidgetKind.upNext

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: upNextProvider) { entry in
            CronicaUpNextWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Up Next"))
        .description(String(localized: "Your next episodes to watch."))
        .supportedFamilies(CronicaWidgetFamilies.upNextFamilies)
    }

    private var upNextProvider: WidgetSnapshotProvider {
        WidgetSnapshotProvider(
            emptyMessage: String(localized: "Nothing up next. Add TV shows in Cronica."),
            readSnapshot: {
                WidgetSnapshotStore.readUpNext()?.items ?? []
            }
        )
    }
}
#endif
