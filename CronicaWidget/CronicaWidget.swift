//
//  CronicaWidget.swift
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

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ItemContentEntry {
        ItemContentEntry(date: Date(), items: Self.placeholderItems())
    }

    func getSnapshot(in context: Context, completion: @escaping (ItemContentEntry) -> ()) {
        let entry = ItemContentEntry(date: Date(), items: Self.placeholderItems())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let nextUpdate = Date().addingTimeInterval(86400)
            do {
                let result = try await NetworkService.shared.fetchItems(from: "trending/all/day")
                let content = Array(result.shuffled().prefix(8))
                let items = await Self.buildDisplayItems(from: content)
                let entry = ItemContentEntry(date: .now, items: items)
                completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            } catch {
                let items = await Self.buildDisplayItems(from: ItemContent.widgetExamples)
                let entry = ItemContentEntry(date: .now, items: items)
                completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            }
        }
    }

    private static func placeholderItems() -> [WidgetDisplayItem] {
        ItemContent.examples.prefix(4).map { WidgetDisplayItem(item: $0, posterData: nil) }
    }

    private static func buildDisplayItems(from content: [ItemContent]) async -> [WidgetDisplayItem] {
        let network = NetworkService.shared
        var items: [WidgetDisplayItem] = []
        items.reserveCapacity(content.count)

        for item in content {
            var posterData: Data?
            if let url = item.posterImageMedium {
                posterData = try? await network.downloadData(from: url)
            }
            items.append(WidgetDisplayItem(item: item, posterData: posterData))
        }
        return items
    }
}

struct ItemContentEntry: TimelineEntry {
    let date: Date
    let items: [WidgetDisplayItem]
}

struct CronicaWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        ItemContentList(items: entry.items)
            .padding(12)
            .containerBackground(for: .widget) {
#if os(iOS)
                Color(uiColor: .systemBackground)
#elseif os(macOS)
                Color(nsColor: .windowBackgroundColor)
#endif
            }
    }
}

@main
struct CronicaWidget: Widget {
    let kind: String = "CronicaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CronicaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Trending")
        .description("Shows movies and TV Shows trending from TMDb.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge
        ])
    }
}
