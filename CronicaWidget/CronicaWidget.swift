//
//  CronicaWidget.swift
//  CronicaWidget
//

import WidgetKit
import SwiftUI
import CronicaCore

@main
struct CronicaWidgetBundle: WidgetBundle {
    var body: some Widget {
        CronicaTrendingWidget()
#if os(iOS)
        if #available(iOS 16.2, *) {
            CronicaUpNextWidget()
            CronicaWatchlistWidget()
            WatchingLiveActivity()
        }
#endif
    }
}

#if DEBUG
#Preview("Trending Small", as: .systemSmall) {
    CronicaTrendingWidget()
} timeline: {
    ItemContentEntry(date: .now, items: ItemContent.widgetExamples.prefix(2).map {
        WidgetDisplayItem(item: $0, posterData: nil)
    })
}
#endif
