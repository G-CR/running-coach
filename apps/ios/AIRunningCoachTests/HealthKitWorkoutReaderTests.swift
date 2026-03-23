import Foundation
import XCTest
@testable import AIRunningCoach

final class HealthKitWorkoutReaderTests: XCTestCase {
    func testReaderNormalizesRecordAndAdvancesAnchor() async throws {
        let source = HealthKitWorkoutSourceStub(records: [.fixture()])
        let sut = HealthKitWorkoutReader(source: source, lastAnchor: nil)

        let workouts = try await sut.readWorkouts(userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!)

        XCTAssertEqual(workouts.count, 1)
        XCTAssertEqual(workouts[0].source, "healthkit")
        XCTAssertEqual(workouts[0].sourceWorkoutID, "hk-1")
        XCTAssertEqual(workouts[0].distanceM, 5_000)
        XCTAssertEqual(sut.lastAnchor, source.records[0].endedAt)
    }
}
