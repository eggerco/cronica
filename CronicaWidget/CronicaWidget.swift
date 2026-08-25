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
    private static let refreshInterval: TimeInterval = 86_400
    private static let trendingPath = "trending/all/day"
    /// Gallery snapshots must not hang; timeline uses the same helper without a race.
    private static let snapshotTimeoutNanoseconds: UInt64 = 5_000_000_000

    func placeholder(in context: Context) -> ItemContentEntry {
        ItemContentEntry(date: Date(), items: Self.bundledPlaceholderItems())
    }

    func getSnapshot(in context: Context, completion: @escaping (ItemContentEntry) -> ()) {
        Task {
            let items: [WidgetDisplayItem]
            if context.isPreview {
                items = Self.bundledPlaceholderItems()
            } else {
                items = await Self.resolveItems(preferNetwork: true, timeoutNanoseconds: Self.snapshotTimeoutNanoseconds)
            }
            completion(ItemContentEntry(date: .now, items: items))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        if context.isPreview {
            let entry = ItemContentEntry(date: .now, items: Self.bundledPlaceholderItems())
            completion(Timeline(entries: [entry], policy: .never))
            return
        }

        Task {
            let nextUpdate = Date().addingTimeInterval(Self.refreshInterval)
            // No artificial timeout — WidgetKit already bounds extension runtime.
            let items = await Self.resolveItems(preferNetwork: true, timeoutNanoseconds: nil)
            let entry = ItemContentEntry(date: .now, items: items)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    /// Live TMDb when possible; otherwise bundled asset placeholders (no network).
    private static func resolveItems(
        preferNetwork: Bool,
        timeoutNanoseconds: UInt64?
    ) async -> [WidgetDisplayItem] {
        guard preferNetwork else {
            return bundledPlaceholderItems()
        }

        guard let timeoutNanoseconds else {
            return await fetchLiveItems() ?? bundledPlaceholderItems()
        }

        return await withTaskGroup(of: [WidgetDisplayItem].self) { group in
            group.addTask {
                await fetchLiveItems() ?? bundledPlaceholderItems()
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return bundledPlaceholderItems()
            }
            let first = await group.next() ?? bundledPlaceholderItems()
            group.cancelAll()
            return first
        }
    }

    private static func fetchLiveItems() async -> [WidgetDisplayItem]? {
        do {
            let result = try await NetworkService.shared.fetchItems(from: trendingPath)
            let content = Array(result.prefix(WidgetPosterLayout.maxFetchedItems))
            guard !content.isEmpty else {
                AppLogger.network.warning("Widget trending fetch returned no items.")
                return nil
            }
            return await buildDisplayItems(from: content)
        } catch {
            AppLogger.network.error("Widget trending fetch failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Asset-backed placeholders — reliable offline / gallery / error UX.
    private static func bundledPlaceholderItems() -> [WidgetDisplayItem] {
        ItemContent.widgetExamples
            .prefix(WidgetPosterLayout.maxFetchedItems)
            .map { WidgetDisplayItem(item: $0, posterData: nil) }
    }

    private static func buildDisplayItems(from content: [ItemContent]) async -> [WidgetDisplayItem] {
        await withTaskGroup(of: (Int, WidgetDisplayItem).self) { group in
            for (index, item) in content.enumerated() {
                group.addTask {
                    var posterData: Data?
                    if let url = item.posterImageMedium {
                        do {
                            posterData = try await NetworkService.shared.downloadData(from: url)
                        } catch {
                            AppLogger.network.debug(
                                "Widget poster download failed for \(item.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
                            )
                        }
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
        .configurationDisplayName(String(localized: "Trending"))
        .description(String(localized: "Shows movies and TV Shows trending from TMDb."))
        .supportedFamilies(CronicaWidgetFamilies.homeScreen)
    }
}

#if DEBUG
#Preview("Small", as: .systemSmall) {
    CronicaWidget()
} timeline: {
    ItemContentEntry(date: .now, items: ItemContent.widgetExamples.prefix(2).map {
        WidgetDisplayItem(item: $0, posterData: nil)
    })
}

#Preview("Medium", as: .systemMedium) {
    CronicaWidget()
} timeline: {
    ItemContentEntry(date: .now, items: ItemContent.widgetExamples.prefix(4).map {
        WidgetDisplayItem(item: $0, posterData: nil)
    })
}

#Preview("Large", as: .systemLarge) {
    CronicaWidget()
} timeline: {
    ItemContentEntry(date: .now, items: ItemContent.widgetExamples.prefix(4).map {
        WidgetDisplayItem(item: $0, posterData: nil)
    })
}
#endif
