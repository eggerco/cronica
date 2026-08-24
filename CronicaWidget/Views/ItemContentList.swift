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

    private var isPhone: Bool {
#if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
#else
        false
#endif
    }

    /// iPhone has no systemExtraLarge slot; large uses the same 8-item grid for consistency.
    private var usesExpandedGrid: Bool {
        family == .systemExtraLarge || (family == .systemLarge && isPhone)
    }

    private var visibleItems: [WidgetDisplayItem] {
        Array(items.prefix(family.displayLimit(isPhone: isPhone)))
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if visibleItems.isEmpty {
                    Text("Trending service isn't available right now.")
                        .font(family == .systemSmall ? .caption : .callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    layout(in: geometry.size)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }

    @ViewBuilder
    private func layout(in size: CGSize) -> some View {
        if usesExpandedGrid {
            gridLayout(
                items: visibleItems,
                in: size,
                columns: WidgetLayout.expandedGridColumns,
                spacing: 8
            )
        } else {
            switch family {
            case .systemSmall, .systemMedium:
                rowLayout(items: visibleItems, in: size, spacing: 6)
            case .systemLarge:
                gridLayout(
                    items: visibleItems,
                    in: size,
                    columns: WidgetLayout.standardLargeColumns,
                    spacing: 8
                )
            default:
                rowLayout(items: visibleItems, in: size, spacing: 6)
            }
        }
    }

    private func rowLayout(items: [WidgetDisplayItem], in size: CGSize, spacing: CGFloat) -> some View {
        let count = CGFloat(max(items.count, 1))
        let totalSpacing = spacing * max(count - 1, 0)
        let posterWidth = (size.width - totalSpacing) / count
        let posterHeight = min(size.height, posterWidth * 1.5)

        return HStack(spacing: spacing) {
            ForEach(items) { entry in
                posterLink(for: entry, width: posterWidth, height: posterHeight)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func gridLayout(items: [WidgetDisplayItem], in size: CGSize, columns: Int, spacing: CGFloat) -> some View {
        let columnCount = CGFloat(max(columns, 1))
        let rowCount = CGFloat(max(Int(ceil(Double(items.count) / Double(columns))), 1))
        let totalHorizontalSpacing = spacing * max(columnCount - 1, 0)
        let totalVerticalSpacing = spacing * max(rowCount - 1, 0)
        let posterWidth = (size.width - totalHorizontalSpacing) / columnCount
        let rowHeight = (size.height - totalVerticalSpacing) / rowCount
        let posterHeight = min(rowHeight, posterWidth * 1.5)

        let gridItems = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)

        return LazyVGrid(columns: gridItems, spacing: spacing) {
            ForEach(items) { entry in
                posterLink(for: entry, width: posterWidth, height: posterHeight)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func posterLink(for entry: WidgetDisplayItem, width: CGFloat, height: CGFloat) -> some View {
        let poster = WidgetPosterView(posterData: entry.posterData, placeholderName: entry.item.placeholderImagePath)
            .frame(width: width, height: height)
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

private enum WidgetLayout {
    static let expandedItemCount = 8
    static let expandedGridColumns = 4
    static let standardLargeItemCount = 6
    static let standardLargeColumns = 3
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
    func displayLimit(isPhone: Bool) -> Int {
        switch self {
        case .systemSmall: 2
        case .systemMedium: 4
        case .systemLarge:
            isPhone ? WidgetLayout.expandedItemCount : WidgetLayout.standardLargeItemCount
        case .systemExtraLarge:
            WidgetLayout.expandedItemCount
        default: 4
        }
    }
}
