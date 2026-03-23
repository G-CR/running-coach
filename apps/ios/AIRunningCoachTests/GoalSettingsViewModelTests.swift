import XCTest
@testable import AIRunningCoach

@MainActor
final class GoalSettingsViewModelTests: XCTestCase {
    func testLoadUsesCurrentAuthorizationStatus() async {
        let goalService = GoalServiceStub()
        let authorizationService = HealthKitAuthorizationServiceStub(currentStatusValue: .pending)
        let sut = GoalSettingsViewModel(
            goalService: goalService,
            authorizationService: authorizationService,
            workoutReader: WorkoutImportReaderStub(result: .success([])),
            syncCoordinator: WorkoutSyncCoordinatorSpy(),
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
        )

        await sut.load()

        XCTAssertEqual(sut.healthKitStatus, HealthKitAuthorizationState.pending.description)
    }

    func testRequestHealthKitAuthorizationUpdatesStatus() async throws {
        let goalService = GoalServiceStub()
        let authorizationService = HealthKitAuthorizationServiceStub(
            currentStatusValue: .pending,
            requestResult: .success(.authorized)
        )
        let sut = GoalSettingsViewModel(
            goalService: goalService,
            authorizationService: authorizationService,
            workoutReader: WorkoutImportReaderStub(result: .success([])),
            syncCoordinator: WorkoutSyncCoordinatorSpy(),
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
        )

        await sut.requestHealthKitAuthorization()

        XCTAssertEqual(authorizationService.requestCallCount, 1)
        XCTAssertEqual(sut.healthKitStatus, HealthKitAuthorizationState.authorized.description)
    }

    func testSyncRecentWorkoutsRequiresAuthorization() async {
        let goalService = GoalServiceStub()
        let authorizationService = HealthKitAuthorizationServiceStub(currentStatusValue: .pending)
        let syncCoordinator = WorkoutSyncCoordinatorSpy()
        let sut = GoalSettingsViewModel(
            goalService: goalService,
            authorizationService: authorizationService,
            workoutReader: WorkoutImportReaderStub(result: .success([.fixture()])),
            syncCoordinator: syncCoordinator,
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
        )

        await sut.syncRecentWorkouts()

        XCTAssertEqual(sut.syncStatus, "请先完成 HealthKit 授权")
        XCTAssertTrue(syncCoordinator.syncedWorkouts.isEmpty)
    }

    func testSyncRecentWorkoutsUploadsImportedRuns() async {
        let goalService = GoalServiceStub()
        let authorizationService = HealthKitAuthorizationServiceStub(currentStatusValue: .authorized)
        let syncCoordinator = WorkoutSyncCoordinatorSpy()
        let workouts = [
            WorkoutImportPayload.fixture(
                userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
            ),
            WorkoutImportPayload.fixture(
                userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
            )
        ]
        let sut = GoalSettingsViewModel(
            goalService: goalService,
            authorizationService: authorizationService,
            workoutReader: WorkoutImportReaderStub(result: .success(workouts)),
            syncCoordinator: syncCoordinator,
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
        )

        await sut.syncRecentWorkouts()

        XCTAssertEqual(syncCoordinator.syncedWorkouts.count, 2)
        XCTAssertEqual(sut.syncStatus, "已同步 2 条跑步训练")
    }
}
