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

    /// Standard movie-poster ratio (width / height). Same on every size and device.
    private static let posterAspect: CGFloat = 2.0 / 3.0
    private static let spacing: CGFloat = 8

    private var visibleItems: [WidgetDisplayItem] {
        Array(items.prefix(family.displayLimit))
    }

    private var gridColumns: Int {
        switch family {
        case .systemLarge: 2
        case .systemExtraLarge: 4
        default: 2
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    /// Single centered row of equal 2∶3 posters.
    private var rowLayout: some View {
        GeometryReader { geo in
            let size = Self.posterSize(
                count: visibleItems.count,
                columns: visibleItems.count,
                rows: 1,
                in: geo.size
            )

            HStack(spacing: Self.spacing) {
                ForEach(visibleItems) { entry in
                    posterCell(for: entry)
                        .frame(width: size.width, height: size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// Centered grid of equal 2∶3 posters — same shape on iPhone and iPad.
    private func gridLayout(columns: Int) -> some View {
        let rows = visibleItems.chunked(into: columns)
        let rowCount = max(rows.count, 1)

        return GeometryReader { geo in
            let size = Self.posterSize(
                count: visibleItems.count,
                columns: columns,
                rows: rowCount,
                in: geo.size
            )

            VStack(spacing: Self.spacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: Self.spacing) {
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

    /// Largest 2∶3 poster that fits the available grid cell on any device.
    private static func posterSize(
        count: Int,
        columns: Int,
        rows: Int,
        in bounds: CGSize
    ) -> CGSize {
        let columnCount = CGFloat(max(columns, 1))
        let rowCount = CGFloat(max(rows, 1))
        let maxWidth = (bounds.width - spacing * (columnCount - 1)) / columnCount
        let maxHeight = (bounds.height - spacing * (rowCount - 1)) / rowCount

        let widthFromHeight = maxHeight * posterAspect
        let width = min(maxWidth, widthFromHeight)
        let height = width / posterAspect

        // Avoid zero-size placeholders when the timeline is empty mid-layout.
        guard count > 0, width.isFinite, height.isFinite, width > 0, height > 0 else {
            return .zero
        }
        return CGSize(width: width, height: height)
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
        // 2×2 — same poster shape as small/medium; drop the cramped third column.
        case .systemLarge: 4
        case .systemExtraLarge: 8
        default: 4
        }
    }
}
