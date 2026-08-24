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
        case .systemSmall:
            smallLayout
        case .systemMedium:
            mediumLayout
        case .systemLarge, .systemExtraLarge:
            gridLayout(columns: family.gridColumnCount)
        default:
            mediumLayout
        }
    }

    private var smallLayout: some View {
        HStack(spacing: 8) {
            ForEach(visibleItems) { entry in
                posterLink(for: entry, width: 68, height: 102)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var mediumLayout: some View {
        HStack(spacing: 6) {
            ForEach(visibleItems) { entry in
                posterLink(for: entry, width: 74, height: 112)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func gridLayout(columns: Int) -> some View {
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
        return LazyVGrid(columns: gridItems, spacing: 8) {
            ForEach(visibleItems) { entry in
                posterLink(for: entry, width: nil, height: family == .systemExtraLarge ? 150 : 130)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func posterLink(for entry: WidgetDisplayItem, width: CGFloat?, height: CGFloat) -> some View {
        let poster = WidgetPosterView(posterData: entry.posterData, placeholderName: entry.item.placeholderImagePath)
            .frame(maxWidth: width == nil ? .infinity : width)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .shadow(radius: 1)

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

    var gridColumnCount: Int {
        switch self {
        case .systemLarge: 3
        case .systemExtraLarge: 4
        default: 2
        }
    }
}
