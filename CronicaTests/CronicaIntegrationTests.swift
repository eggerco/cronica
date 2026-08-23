import XCTest
@testable import Cronica

final class CronicaIntegrationTests: XCTestCase {
    func testPersistenceRoundTripForWatchedState() {
        let persistence = PersistenceController(inMemory: true)
        guard let sample = ItemContent.examples.first else {
            XCTFail("Missing preview content")
            return
        }
        persistence.save(sample)
        guard let saved = persistence.fetch(for: sample.itemContentID) else {
            XCTFail("Saved item not found")
            return
        }
        persistence.updateWatched(for: saved)
        XCTAssertTrue(persistence.isMarkedAsWatched(id: sample.itemContentID))
    }

    func testNetworkServiceInvalidItemID() async {
        do {
            _ = try await NetworkService.shared.fetchItem(id: 0, type: .movie)
            XCTFail("Expected content removed error")
        } catch let error as NetworkError {
            XCTAssertEqual(error.localizedName, NetworkError.contentRemoved.localizedName)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
