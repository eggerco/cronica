//
//  LiveActivityPosterStoreTests.swift
//  CronicaCoreTests
//

import XCTest
@testable import CronicaCore

final class LiveActivityPosterStoreTests: XCTestCase {
    func testSaveLoadRemoveRoundTripWhenAppGroupAvailable() throws {
        guard WidgetAppGroup.containerURL != nil else {
            throw XCTSkip("App Group container unavailable in this test environment")
        }

        let contentID = "live-activity-test@0"
        let payload = Data([0x01, 0x02, 0x03, 0x04])
        defer { LiveActivityPosterStore.remove(contentID: contentID) }

        LiveActivityPosterStore.save(payload, contentID: contentID)
        XCTAssertEqual(LiveActivityPosterStore.load(contentID: contentID), payload)

        LiveActivityPosterStore.remove(contentID: contentID)
        XCTAssertNil(LiveActivityPosterStore.load(contentID: contentID))
    }
}
