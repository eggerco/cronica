import XCTest
@testable import CronicaCore

final class WidgetPosterLayoutTests: XCTestCase {
    func testDisplayLimits() {
        XCTAssertEqual(WidgetPosterLayout.Family.small.displayLimit, 2)
        XCTAssertEqual(WidgetPosterLayout.Family.medium.displayLimit, 4)
        XCTAssertEqual(WidgetPosterLayout.Family.large.displayLimit, 6)
        XCTAssertEqual(WidgetPosterLayout.Family.extraLarge.displayLimit, 12)
        XCTAssertGreaterThanOrEqual(
            WidgetPosterLayout.maxFetchedItems,
            WidgetPosterLayout.Family.extraLarge.displayLimit
        )
    }

    func testGridColumnsFillEvenly() {
        XCTAssertEqual(WidgetPosterLayout.Family.large.displayLimit % WidgetPosterLayout.Family.large.gridColumns, 0)
        XCTAssertEqual(
            WidgetPosterLayout.Family.extraLarge.displayLimit % WidgetPosterLayout.Family.extraLarge.gridColumns,
            0
        )
    }

    func testPosterSizeKeepsAspectRatio() {
        let size = WidgetPosterLayout.posterSize(
            columns: 4,
            rows: 1,
            in: CGSize(width: 320, height: 200)
        )
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertEqual(size.width / size.height, WidgetPosterLayout.aspectRatio, accuracy: 0.001)
    }

    func testPosterSizeFitsMediumRow() {
        let bounds = CGSize(width: 329, height: 155)
        let size = WidgetPosterLayout.posterSize(columns: 4, rows: 1, in: bounds)
        XCTAssertLessThanOrEqual(size.width * 4 + WidgetPosterLayout.spacing * 3, bounds.width + 0.5)
        XCTAssertLessThanOrEqual(size.height, bounds.height + 0.5)
    }

    func testPosterSizeFitsLargeGrid() {
        let bounds = CGSize(width: 329, height: 345)
        let gap = WidgetPosterLayout.spacing(for: .large)
        let size = WidgetPosterLayout.posterSize(columns: 3, rows: 2, in: bounds, spacing: gap)
        XCTAssertLessThanOrEqual(size.width * 3 + gap * 2, bounds.width + 0.5)
        XCTAssertLessThanOrEqual(size.height * 2 + gap, bounds.height + 0.5)
        XCTAssertEqual(size.width / size.height, WidgetPosterLayout.aspectRatio, accuracy: 0.001)
    }

    func testPosterSizeFitsIPadExtraLargeGrid() {
        // Approximate iPad Extra Large widget content size — 6×2 (extras beside, not a 3rd row).
        let bounds = CGSize(width: 720, height: 340)
        let gap = WidgetPosterLayout.spacing(for: .extraLarge)
        let size = WidgetPosterLayout.posterSize(columns: 6, rows: 2, in: bounds, spacing: gap)
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertLessThanOrEqual(size.width * 6 + gap * 5, bounds.width + 0.5)
        XCTAssertLessThanOrEqual(size.height * 2 + gap, bounds.height + 0.5)
        XCTAssertEqual(size.width / size.height, WidgetPosterLayout.aspectRatio, accuracy: 0.001)
    }

    func testPosterSizeRejectsInvalidBounds() {
        XCTAssertEqual(WidgetPosterLayout.posterSize(columns: 2, rows: 2, in: .zero), .zero)
    }
}
