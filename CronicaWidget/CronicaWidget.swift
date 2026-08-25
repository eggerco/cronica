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
        if context.isPreview {
            let entry = ItemContentEntry(date: .now, items: Self.placeholderItems())
            completion(Timeline(entries: [entry], policy: .never))
            return
        }

        Task {
            let nextUpdate = Date().addingTimeInterval(86400)
            do {
                let result = try await NetworkService.shared.fetchItems(from: "trending/all/day")
                let content = Array(result.prefix(8))
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
        ItemContent.widgetExamples.prefix(4).map { WidgetDisplayItem(item: $0, posterData: nil) }
    }

    private static func buildDisplayItems(from content: [ItemContent]) async -> [WidgetDisplayItem] {
        await withTaskGroup(of: (Int, WidgetDisplayItem).self) { group in
            for (index, item) in content.enumerated() {
                group.addTask {
                    var posterData: Data?
                    if let url = item.posterImageMedium {
                        posterData = try? await NetworkService.shared.downloadData(from: url)
                    }
                    return (index, WidgetDisplayItem(item: item, posterData: posterData))
                }
            }

            var ordered = [WidgetDisplayItem?](repeating: nil, count: content.count)
            for await (index, item) in group {
                ordered[index] = item
            }
            return ordered.compactMap { $0 }
        }
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
            .padding(10)
            .clipped()
            .containerBackground(for: .widget) {
#if os(iOS)
                Color(uiColor: .systemBackground)
#elseif os(macOS)
                Color(nsColor: .windowBackgroundColor)
#endif
            }
    }
}

private enum CronicaWidgetFamilies {
    static let homeScreen: [WidgetFamily] = {
#if os(iOS)
        var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
        if UIDevice.current.userInterfaceIdiom == .pad {
            families.append(.systemExtraLarge)
        }
        return families
#elseif os(macOS)
        [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]
#else
        [.systemSmall, .systemMedium, .systemLarge]
#endif
    }()
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
        .supportedFamilies(CronicaWidgetFamilies.homeScreen)
    }
}
