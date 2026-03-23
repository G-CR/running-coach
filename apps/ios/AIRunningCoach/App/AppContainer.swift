import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let authSession: InMemoryAuthSession
    let apiClient: APIClient
    let queueStore: InMemorySyncQueueStore
    let authorizationService: HealthKitAuthorizationService
    let workoutReader: HealthKitWorkoutReader
    let syncCoordinator: WorkoutSyncCoordinator
    let homeService: HomeServing
    let workoutService: WorkoutServing
    let planService: PlanServing
    let goalService: GoalServing

    init(
        authSession: InMemoryAuthSession,
        apiClient: APIClient,
        queueStore: InMemorySyncQueueStore,
        authorizationService: HealthKitAuthorizationService,
        workoutReader: HealthKitWorkoutReader,
        syncCoordinator: WorkoutSyncCoordinator,
        homeService: HomeServing,
        workoutService: WorkoutServing,
        planService: PlanServing,
        goalService: GoalServing
    ) {
        self.authSession = authSession
        self.apiClient = apiClient
        self.queueStore = queueStore
        self.authorizationService = authorizationService
        self.workoutReader = workoutReader
        self.syncCoordinator = syncCoordinator
        self.homeService = homeService
        self.workoutService = workoutService
        self.planService = planService
        self.goalService = goalService
    }

    static func live(baseURL: URL = URL(string: "http://localhost:8000")!) -> AppContainer {
        let resolvedBaseURL = AppRuntimeConfiguration.resolveAPIBaseURL()
        let authSession = InMemoryAuthSession(accessToken: LocalDevelopmentIdentity.bearerToken())
        let apiClient = APIClient(baseURL: resolvedBaseURL, authSession: authSession)
        let queueStore = InMemorySyncQueueStore()
        let authorizationService = HealthKitAuthorizationService()
        let workoutReader = HealthKitWorkoutReader(source: LiveHealthKitWorkoutSource())
        let syncCoordinator = WorkoutSyncCoordinator(apiClient: apiClient, queueStore: queueStore)
        let store = DemoAppStore.demo()
        return AppContainer(
            authSession: authSession,
            apiClient: apiClient,
            queueStore: queueStore,
            authorizationService: authorizationService,
            workoutReader: workoutReader,
            syncCoordinator: syncCoordinator,
            homeService: DemoHomeService(store: store),
            workoutService: DemoWorkoutService(store: store),
            planService: DemoPlanService(store: store),
            goalService: DemoGoalService(store: store)
        )
    }

    var localUserID: UUID {
        LocalDevelopmentIdentity.userID()
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
