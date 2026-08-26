//
//  WidgetSnapshotStoreTests.swift
//  CronicaCoreTests
//

import XCTest
@testable import CronicaCore

final class WidgetSnapshotStoreTests: XCTestCase {
    func testPosterFileNameSanitizesContentID() {
        XCTAssertEqual(
            WidgetSnapshotStore.posterFileName(for: "123@1"),
            "123_1.jpg"
        )
    }

    func testSnapshotRoundTripEncoding() throws {
        let item = WidgetSnapshotItem(
            id: "42@1",
            title: "Example Show",
            subtitle: "S2 · E5",
            deepLink: "cronica://42@1",
            posterFileName: "42_1.jpg",
            watchProgress: 0.35,
            sortDate: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let snapshot = WidgetUpNextSnapshot(items: [item], updatedAt: Date(timeIntervalSince1970: 1_700_000_100))

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetUpNextSnapshot.self, from: data)

        XCTAssertEqual(decoded.items.count, 1)
        XCTAssertEqual(decoded.items[0].id, "42@1")
        XCTAssertEqual(decoded.items[0].subtitle, "S2 · E5")
        XCTAssertEqual(decoded.items[0].watchProgress, 0.35, accuracy: 0.001)
    }

    func testWidgetKindIdentifiersAreStable() {
        XCTAssertEqual(WidgetKind.trending, "CronicaWidget")
        XCTAssertEqual(WidgetKind.upNext, "CronicaUpNextWidget")
        XCTAssertEqual(WidgetKind.watchlist, "CronicaWatchlistWidget")
    }

    func testPruneUnusedPostersKeepsReferencedFiles() throws {
        guard WidgetAppGroup.containerURL != nil else {
            throw XCTSkip("App Group container unavailable in this test environment")
        }

        let keep = "keep_poster.jpg"
        let drop = "drop_poster.jpg"
        defer {
            try? FileManager.default.removeItem(
                at: WidgetAppGroup.containerURL!.appendingPathComponent("posters").appendingPathComponent(keep)
            )
            try? FileManager.default.removeItem(
                at: WidgetAppGroup.containerURL!.appendingPathComponent("posters").appendingPathComponent(drop)
            )
        }

        try WidgetSnapshotStore.writePoster(Data([0xFF, 0xD8]), fileName: keep)
        try WidgetSnapshotStore.writePoster(Data([0xFF, 0xD9]), fileName: drop)
        WidgetSnapshotStore.pruneUnusedPosters(keeping: [keep])

        XCTAssertNotNil(WidgetSnapshotStore.readPoster(named: keep))
        XCTAssertNil(WidgetSnapshotStore.readPoster(named: drop))
    }
}
