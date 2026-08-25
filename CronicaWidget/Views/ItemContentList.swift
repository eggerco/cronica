//
//  ItemContentList.swift
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

struct WidgetDisplayItem: Identifiable {
    let item: ItemContent
    let posterData: Data?

    var id: Int { item.id }
}

struct ItemContentList: View {
    @Environment(\.widgetFamily) private var family
    let items: [WidgetDisplayItem]

    private var layoutFamily: WidgetPosterLayout.Family {
        switch family {
        case .systemSmall: .small
        case .systemMedium: .medium
        case .systemLarge: .large
        case .systemExtraLarge: .extraLarge
        default: .medium
        }
    }

    private var visibleItems: [WidgetDisplayItem] {
        Array(items.prefix(layoutFamily.displayLimit))
    }

    var body: some View {
        Group {
            if visibleItems.isEmpty {
                Text(String(localized: "Trending service isn't available right now."))
                    .font(family == .systemSmall ? .caption : .callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityElement(children: .combine)
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
            let size = WidgetPosterLayout.posterSize(
                columns: max(visibleItems.count, 1),
                rows: 1,
                in: geo.size
            )

            HStack(spacing: WidgetPosterLayout.spacing) {
                ForEach(visibleItems) { entry in
                    posterCell(for: entry)
                        .frame(width: size.width, height: size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func gridLayout(columns: Int) -> some View {
        let rows = visibleItems.chunked(into: columns)
        let rowCount = max(rows.count, 1)

        return GeometryReader { geo in
            let size = WidgetPosterLayout.posterSize(
                columns: columns,
                rows: rowCount,
                in: geo.size
            )

            VStack(spacing: WidgetPosterLayout.spacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: WidgetPosterLayout.spacing) {
                        ForEach(row) { entry in
                            posterCell(for: entry)
                                .frame(width: size.width, height: size.height)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private func posterCell(for entry: WidgetDisplayItem) -> some View {
        let poster = WidgetPosterView(
            posterData: entry.posterData,
            placeholderName: entry.item.placeholderImagePath
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        if let destination = entry.item.cronicaDeepLinkURL {
            Link(destination: destination) {
                poster
            }
            .accessibilityLabel(entry.item.itemTitle)
        } else {
            poster
                .accessibilityLabel(entry.item.itemTitle)
        }
    }
}

private struct WidgetPosterView: View {
    let posterData: Data?
    let placeholderName: String?

    var body: some View {
        Group {
            if let posterData, let image = platformImage(from: posterData) {
                image
                    .resizable()
                    .scaledToFill()
            } else if let placeholderName {
                Image(placeholderName)
                    .resizable()
                    .scaledToFill()
            } else {
                PlaceholderImage()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .accessibilityHidden(true)
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
