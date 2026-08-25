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

    private var visibleItems: [WidgetDisplayItem] {
        Array(items.prefix(family.displayLimit))
    }

    private var gridColumns: Int {
        switch family {
        case .systemLarge: 3
        case .systemExtraLarge: 4
        default: 3
        }
    }

    var body: some View {
        Group {
            if visibleItems.isEmpty {
                Text("Trending service isn't available right now.")
                    .font(family == .systemSmall ? .caption : .callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                layout
            }
        }
    }

    @ViewBuilder
    private var layout: some View {
        switch family {
        case .systemSmall, .systemMedium:
            rowLayout
        case .systemLarge, .systemExtraLarge:
            gridLayout(columns: gridColumns)
        default:
            rowLayout
        }
    }

    private var rowLayout: some View {
        HStack(spacing: 8) {
            ForEach(visibleItems) { entry in
                posterLink(for: entry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func gridLayout(columns: Int) -> some View {
        let rows = visibleItems.chunked(into: columns)
        return VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row) { entry in
                        posterLink(for: entry)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    if row.count < columns {
                        ForEach(0..<(columns - row.count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func posterLink(for entry: WidgetDisplayItem) -> some View {
        let poster = WidgetPosterView(posterData: entry.posterData, placeholderName: entry.item.placeholderImagePath)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        if let destination = entry.item.cronicaDeepLinkURL {
            Link(destination: destination) {
                poster
            }
        } else {
            poster
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
                    .aspectRatio(contentMode: .fill)
            } else if let placeholderName {
                Image(placeholderName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                PlaceholderImage()
            }
        }
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

private extension WidgetFamily {
    var displayLimit: Int {
        switch self {
        case .systemSmall: 2
        case .systemMedium: 4
        case .systemLarge: 6
        case .systemExtraLarge: 8
        default: 4
        }
    }
}
