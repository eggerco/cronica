//
//  WidgetPosterLayout.swift
//  CronicaCore
//

import CoreGraphics
import Foundation

/// Shared Trending-widget poster geometry.
/// One 2∶3 rule for every Home Screen size — kept in CronicaCore so CI can test it.
public enum WidgetPosterLayout {
    public enum Family: String, CaseIterable, Sendable {
        case small
        case medium
        case large
        case extraLarge

        public var displayLimit: Int {
            switch self {
            case .small: 2
            case .medium, .large: 4
            case .extraLarge: 8
            }
        }

        public var gridColumns: Int {
            switch self {
            case .large: 2
            case .extraLarge: 4
            case .small, .medium: 2
            }
        }
    }

    /// Poster width ÷ height.
    public static let aspectRatio: CGFloat = 2.0 / 3.0
    public static let spacing: CGFloat = 8
    public static let maxFetchedItems = 8

    /// Largest 2∶3 poster that fits an equal `columns` × `rows` grid inside `bounds`.
    public static func posterSize(
        columns: Int,
        rows: Int,
        in bounds: CGSize,
        spacing: CGFloat = spacing
    ) -> CGSize {
        let columnCount = CGFloat(max(columns, 1))
        let rowCount = CGFloat(max(rows, 1))
        let maxWidth = (bounds.width - spacing * (columnCount - 1)) / columnCount
        let maxHeight = (bounds.height - spacing * (rowCount - 1)) / rowCount

        guard maxWidth.isFinite, maxHeight.isFinite, maxWidth > 0, maxHeight > 0 else {
            return .zero
        }

        let width = min(maxWidth, maxHeight * aspectRatio)
        let height = width / aspectRatio

        guard width.isFinite, height.isFinite, width > 0, height > 0 else {
            return .zero
        }
        return CGSize(width: width, height: height)
    }
}
