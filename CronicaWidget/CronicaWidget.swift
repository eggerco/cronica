//
//  CronicaWidget.swift
//  CronicaWidget
//

import WidgetKit
import SwiftUI
import CronicaCore

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ItemContentEntry {
        ItemContentEntry(date: Date(), item: ItemContent.examples)
    }

    func getSnapshot(in context: Context, completion: @escaping (ItemContentEntry) -> ()) {
        let entry = ItemContentEntry(date: Date(), item: ItemContent.examples)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let nextUpdate = Date().addingTimeInterval(86400)
            do {
                let result = try await NetworkService.shared.fetchItems(from: "trending/all/day")
                let content = Array(result.shuffled().prefix(4))
                let entry = ItemContentEntry(date: .now, item: content)
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = ItemContentEntry(date: .now, item: ItemContent.widgetExamples)
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }
}

struct ItemContentEntry: TimelineEntry {
    let date: Date
    let item: [ItemContent]
}

struct CronicaWidgetEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        VStack(alignment: .leading) {
            ItemContentList(items: entry.item)
        }
        .padding()
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
        .supportedFamilies([.systemMedium])
    }
}
