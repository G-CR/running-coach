import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let authSession: InMemoryAuthSession
    let apiClient: APIClient
    let queueStore: InMemorySyncQueueStore
    let authorizationService: HealthKitAuthorizationService
    let workoutReader: HealthKitWorkoutReader
    let syncCoordinator: WorkoutSyncCoordinator

    init(
        authSession: InMemoryAuthSession,
        apiClient: APIClient,
        queueStore: InMemorySyncQueueStore,
        authorizationService: HealthKitAuthorizationService,
        workoutReader: HealthKitWorkoutReader,
        syncCoordinator: WorkoutSyncCoordinator
    ) {
        self.authSession = authSession
        self.apiClient = apiClient
        self.queueStore = queueStore
        self.authorizationService = authorizationService
        self.workoutReader = workoutReader
        self.syncCoordinator = syncCoordinator
    }

    static func live(baseURL: URL = URL(string: "http://localhost:8000")!) -> AppContainer {
        let authSession = InMemoryAuthSession()
        let apiClient = APIClient(baseURL: baseURL, authSession: authSession)
        let queueStore = InMemorySyncQueueStore()
        let authorizationService = HealthKitAuthorizationService()
        let workoutReader = HealthKitWorkoutReader(source: EmptyHealthKitWorkoutSource())
        let syncCoordinator = WorkoutSyncCoordinator(apiClient: apiClient, queueStore: queueStore)
        return AppContainer(
            authSession: authSession,
            apiClient: apiClient,
            queueStore: queueStore,
            authorizationService: authorizationService,
            workoutReader: workoutReader,
            syncCoordinator: syncCoordinator
        )
    }

    var authorizationStatusModel: AuthorizationStatusModel {
        let state = authorizationService.currentStatus()
        return AuthorizationStatusModel(
            title: "HealthKit",
            detail: state.description,
            isAuthorized: state == .authorized
        )
    }
}

private struct EmptyHealthKitWorkoutSource: HealthKitWorkoutSource {
    func readWorkouts(since anchor: Date?) async throws -> [HealthKitWorkoutRecord] {
        _ = anchor
        return []
    }
}
