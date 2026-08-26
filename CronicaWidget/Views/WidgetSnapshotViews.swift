//
//  WidgetSnapshotViews.swift
//  CronicaWidget
//

import SwiftUI
import WidgetKit
import CronicaCore
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct WidgetSnapshotEntry: TimelineEntry {
    let date: Date
    let items: [WidgetSnapshotItem]
    let emptyMessage: String
}

struct WidgetSnapshotProvider: TimelineProvider {
    let emptyMessage: String
    let readSnapshot: () -> [WidgetSnapshotItem]

    func placeholder(in context: Context) -> WidgetSnapshotEntry {
        WidgetSnapshotEntry(date: .now, items: placeholderItems, emptyMessage: emptyMessage)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetSnapshotEntry) -> Void) {
        let items = context.isPreview ? placeholderItems : readSnapshot()
        completion(WidgetSnapshotEntry(date: .now, items: items, emptyMessage: emptyMessage))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetSnapshotEntry>) -> Void) {
        let items = context.isPreview ? placeholderItems : readSnapshot()
        let entry = WidgetSnapshotEntry(date: .now, items: items, emptyMessage: emptyMessage)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private var placeholderItems: [WidgetSnapshotItem] {
        ItemContent.widgetExamples.prefix(2).map { example in
            WidgetSnapshotItem(
                id: example.itemContentID,
                title: example.itemTitle,
                subtitle: "S1 · E1",
                deepLink: "cronica://\(example.itemContentID)",
                posterFileName: nil,
                watchProgress: 0.2,
                sortDate: .now
            )
        }
    }
}

struct WidgetSnapshotHomeView: View {
    @Environment(\.widgetFamily) private var family
    let items: [WidgetSnapshotItem]
    let emptyMessage: String

    private var layoutFamily: WidgetPosterLayout.Family {
        switch family {
        case .systemSmall: .small
        case .systemMedium: .medium
        case .systemLarge: .large
        case .systemExtraLarge: .extraLarge
        default: .medium
        }
    }

    private var visibleItems: [WidgetSnapshotItem] {
        Array(items.prefix(layoutFamily.displayLimit))
    }

    var body: some View {
        Group {
            if visibleItems.isEmpty {
                Text(emptyMessage)
                    .font(family == .systemSmall ? .caption : .callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                layout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var layout: some View {
        switch family {
        case .systemSmall, .systemMedium:
            rowLayout
        case .systemLarge, .systemExtraLarge:
            gridLayout(columns: layoutFamily.gridColumns)
        default:
            rowLayout
        }
    }

    private var rowLayout: some View {
        GeometryReader { geo in
            let gap = WidgetPosterLayout.spacing(for: layoutFamily)
            let size = WidgetPosterLayout.posterSize(
                columns: max(visibleItems.count, 1),
                rows: 1,
                in: geo.size,
                spacing: gap
            )

            HStack(spacing: gap) {
                ForEach(visibleItems) { item in
                    snapshotCell(for: item)
                        .frame(width: size.width, height: size.height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func gridLayout(columns: Int) -> some View {
        let rows = visibleItems.chunked(into: columns)
        let rowCount = max(rows.count, 1)
        let gap = WidgetPosterLayout.spacing(for: layoutFamily)

        return GeometryReader { geo in
            let size = WidgetPosterLayout.posterSize(
                columns: columns,
                rows: rowCount,
                in: geo.size,
                spacing: gap
            )

            VStack(spacing: gap) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: gap) {
                        ForEach(row) { item in
                            snapshotCell(for: item)
                                .frame(width: size.width, height: size.height)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private func snapshotCell(for item: WidgetSnapshotItem) -> some View {
        let poster = WidgetSnapshotPosterView(fileName: item.posterFileName)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                if item.watchProgress > 0, family != .systemSmall {
                    ProgressView(value: item.watchProgress)
                        .tint(.white)
                        .padding(4)
                }
            }

        if let destination = URL(string: item.deepLink) {
            Link(destination: destination) {
                poster
            }
            .accessibilityLabel(item.title)
        } else {
            poster.accessibilityLabel(item.title)
        }
    }
}

#if os(iOS)
struct WidgetSnapshotLockScreenView: View {
    @Environment(\.widgetFamily) private var family
    let items: [WidgetSnapshotItem]
    let emptyMessage: String

    var body: some View {
        Group {
            if let item = items.first {
                switch family {
                case .accessoryInline:
                    Text(inlineText(for: item))
                        .widgetAccentable()
                case .accessoryCircular:
                    ZStack {
                        AccessoryWidgetBackground()
                        Image(systemName: "play.tv")
                    }
                    .widgetAccentable()
                default:
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.headline)
                            .lineLimit(1)
                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(emptyMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(items.first.flatMap { URL(string: $0.deepLink) })
    }

    private func inlineText(for item: WidgetSnapshotItem) -> String {
        if let subtitle = item.subtitle {
            return "\(item.title) · \(subtitle)"
        }
        return item.title
    }
}
#endif

struct WidgetSnapshotPosterView: View {
    let fileName: String?

    var body: some View {
        Group {
            if let fileName,
               let data = WidgetSnapshotStore.readPoster(named: fileName),
               let image = platformImage(from: data) {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                PlaceholderImage()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private func platformImage(from data: Data) -> Image? {
#if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
#elseif os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
#else
        return nil
#endif
    }
}

private struct PlaceholderImage: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color.gray.gradient)
            Image(systemName: "popcorn")
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return isEmpty ? [] : [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
