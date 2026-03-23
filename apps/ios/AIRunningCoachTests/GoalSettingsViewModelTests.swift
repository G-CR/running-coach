import XCTest
@testable import AIRunningCoach

@MainActor
final class GoalSettingsViewModelTests: XCTestCase {
    func testLoadUsesCurrentAuthorizationStatus() async {
        let goalService = GoalServiceStub()
        let authorizationService = HealthKitAuthorizationServiceStub(currentStatusValue: .pending)
        let runtimeConfiguration = AppRuntimeConfigurationServiceStub(
            resolvedURL: URL(string: "http://10.0.0.8:8000")!
        )
        let sut = GoalSettingsViewModel(
            goalService: goalService,
            authorizationService: authorizationService,
            workoutReader: WorkoutImportReaderStub(result: .success([])),
            syncCoordinator: WorkoutSyncCoordinatorSpy(),
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            runtimeConfiguration: runtimeConfiguration,
            apiHealthChecker: APIHealthCheckerStub()
        )

        await sut.load()

        XCTAssertEqual(sut.healthKitStatus, HealthKitAuthorizationState.pending.description)
        XCTAssertEqual(sut.apiBaseURLText, "http://10.0.0.8:8000")
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
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            runtimeConfiguration: AppRuntimeConfigurationServiceStub(),
            apiHealthChecker: APIHealthCheckerStub()
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
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            runtimeConfiguration: AppRuntimeConfigurationServiceStub(),
            apiHealthChecker: APIHealthCheckerStub()
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
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            runtimeConfiguration: AppRuntimeConfigurationServiceStub(),
            apiHealthChecker: APIHealthCheckerStub()
        )

        await sut.syncRecentWorkouts()

        XCTAssertEqual(syncCoordinator.syncedWorkouts.count, 2)
        XCTAssertEqual(sut.syncStatus, "已同步 2 条跑步训练")
    }

    func testSaveAPIBaseURLPersistsEditableValue() async {
        let runtimeConfiguration = AppRuntimeConfigurationServiceStub(
            saveResult: .success(URL(string: "http://192.168.1.30:9000")!)
        )
        let sut = GoalSettingsViewModel(
            goalService: GoalServiceStub(),
            authorizationService: HealthKitAuthorizationServiceStub(),
            workoutReader: WorkoutImportReaderStub(result: .success([])),
            syncCoordinator: WorkoutSyncCoordinatorSpy(),
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            runtimeConfiguration: runtimeConfiguration,
            apiHealthChecker: APIHealthCheckerStub()
        )
        sut.apiBaseURLText = " http://192.168.1.30:9000 "

        await sut.saveAPIBaseURL()

        XCTAssertEqual(runtimeConfiguration.savedValues, [" http://192.168.1.30:9000 "])
        XCTAssertEqual(sut.apiBaseURLText, "http://192.168.1.30:9000")
        XCTAssertEqual(sut.apiBaseURLStatus, "API 地址已更新")
    }

    func testSaveAPIBaseURLShowsValidationError() async {
        let runtimeConfiguration = AppRuntimeConfigurationServiceStub(
            saveResult: .failure(AppRuntimeConfigurationError.invalidAPIBaseURL)
        )
        let sut = GoalSettingsViewModel(
            goalService: GoalServiceStub(),
            authorizationService: HealthKitAuthorizationServiceStub(),
            workoutReader: WorkoutImportReaderStub(result: .success([])),
            syncCoordinator: WorkoutSyncCoordinatorSpy(),
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            runtimeConfiguration: runtimeConfiguration,
            apiHealthChecker: APIHealthCheckerStub()
        )
        sut.apiBaseURLText = "bad-url"

        await sut.saveAPIBaseURL()

        XCTAssertEqual(sut.apiBaseURLStatus, "请输入有效的 http(s) API 地址")
    }

    func testResetAPIBaseURLUsesResolvedDefaultValue() async {
        let runtimeConfiguration = AppRuntimeConfigurationServiceStub(
            resolvedURL: URL(string: "http://192.168.1.30:9000")!,
            resetURL: URL(string: "http://10.0.0.8:8000")!
        )
        let sut = GoalSettingsViewModel(
            goalService: GoalServiceStub(),
            authorizationService: HealthKitAuthorizationServiceStub(),
            workoutReader: WorkoutImportReaderStub(result: .success([])),
            syncCoordinator: WorkoutSyncCoordinatorSpy(),
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            runtimeConfiguration: runtimeConfiguration,
            apiHealthChecker: APIHealthCheckerStub()
        )
        sut.apiBaseURLText = "http://192.168.1.30:9000"

        await sut.resetAPIBaseURL()

        XCTAssertEqual(runtimeConfiguration.resetCallCount, 1)
        XCTAssertEqual(sut.apiBaseURLText, "http://10.0.0.8:8000")
        XCTAssertEqual(sut.apiBaseURLStatus, "已恢复默认 API 地址")
    }

    func testCheckAPIConnectivityUsesCurrentAddress() async {
        let runtimeConfiguration = AppRuntimeConfigurationServiceStub(
            saveResult: .success(URL(string: "http://192.168.1.30:9000")!)
        )
        let healthChecker = APIHealthCheckerStub()
        let sut = GoalSettingsViewModel(
            goalService: GoalServiceStub(),
            authorizationService: HealthKitAuthorizationServiceStub(),
            workoutReader: WorkoutImportReaderStub(result: .success([])),
            syncCoordinator: WorkoutSyncCoordinatorSpy(),
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            runtimeConfiguration: runtimeConfiguration,
            apiHealthChecker: healthChecker
        )
        sut.apiBaseURLText = "http://192.168.1.30:9000"

        await sut.checkAPIConnectivity()

        XCTAssertEqual(healthChecker.checkedURLs, [URL(string: "http://192.168.1.30:9000")!])
        XCTAssertEqual(sut.apiConnectivityStatus, "API 连通正常")
    }

    func testCheckAPIConnectivityRejectsInvalidAddress() async {
        let sut = GoalSettingsViewModel(
            goalService: GoalServiceStub(),
            authorizationService: HealthKitAuthorizationServiceStub(),
            workoutReader: WorkoutImportReaderStub(result: .success([])),
            syncCoordinator: WorkoutSyncCoordinatorSpy(),
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            runtimeConfiguration: AppRuntimeConfigurationServiceStub(),
            apiHealthChecker: APIHealthCheckerStub()
        )
        sut.apiBaseURLText = "bad-url"

        await sut.checkAPIConnectivity()

        XCTAssertEqual(sut.apiConnectivityStatus, "请输入有效的 http(s) API 地址")
    }

    func testCheckAPIConnectivityShowsConnectionFailure() async {
        enum SampleError: Error {
            case offline
        }

        let healthChecker = APIHealthCheckerStub(result: .failure(SampleError.offline))
        let sut = GoalSettingsViewModel(
            goalService: GoalServiceStub(),
            authorizationService: HealthKitAuthorizationServiceStub(),
            workoutReader: WorkoutImportReaderStub(result: .success([])),
            syncCoordinator: WorkoutSyncCoordinatorSpy(),
            userID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            runtimeConfiguration: AppRuntimeConfigurationServiceStub(),
            apiHealthChecker: healthChecker
        )
        sut.apiBaseURLText = "http://192.168.1.30:9000"

        await sut.checkAPIConnectivity()

        XCTAssertEqual(sut.apiConnectivityStatus, "无法连接到 API，请检查地址和服务状态")
    }
}
