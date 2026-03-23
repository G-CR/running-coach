import XCTest
@testable import AIRunningCoach

final class WorkoutSyncCoordinatorTests: XCTestCase {
    func testSyncCoordinatorQueuesWorkoutWhenUploadFails() async throws {
        let api = APIClientStub(result: .failure(.network))
        let store = InMemorySyncQueueStore()
        let sut = WorkoutSyncCoordinator(apiClient: api, queueStore: store)

        do {
            try await sut.sync(workout: .fixture())
            XCTFail("Expected sync to throw")
        } catch {
            XCTAssertEqual(error as? APIClientError, .network)
        }

        let pendingItems = await store.snapshot()
        XCTAssertEqual(pendingItems.count, 1)
    }

    func testRetryPendingUploadsQueuedWorkouts() async throws {
        let api = APIClientStub(result: .success(.fixture()))
        let store = InMemorySyncQueueStore()
        await store.enqueue(.fixture())
        let sut = WorkoutSyncCoordinator(apiClient: api, queueStore: store)

        await sut.retryPending()

        let pendingItems = await store.snapshot()
        XCTAssertEqual(api.importCallCount, 1)
        XCTAssertTrue(pendingItems.isEmpty)
    }
}
