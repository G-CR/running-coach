import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let authSession: InMemoryAuthSession
    let queueStore: InMemorySyncQueueStore
    let runtimeConfiguration: AppRuntimeConfigurationServing
    let setupGuideStateService: SetupGuideStateServing
    let authorizationService: HealthKitAuthorizationService
    let workoutReader: HealthKitWorkoutReader
    let syncCoordinator: WorkoutSyncCoordinator
    let apiHealthChecker: APIHealthChecking
    let homeService: HomeServing
    let workoutService: WorkoutServing
    let planService: PlanServing
    let goalService: GoalServing

    init(
        authSession: InMemoryAuthSession,
        queueStore: InMemorySyncQueueStore,
        runtimeConfiguration: AppRuntimeConfigurationServing,
        setupGuideStateService: SetupGuideStateServing,
        authorizationService: HealthKitAuthorizationService,
        workoutReader: HealthKitWorkoutReader,
        syncCoordinator: WorkoutSyncCoordinator,
        apiHealthChecker: APIHealthChecking,
        homeService: HomeServing,
        workoutService: WorkoutServing,
        planService: PlanServing,
        goalService: GoalServing
    ) {
        self.authSession = authSession
        self.queueStore = queueStore
        self.runtimeConfiguration = runtimeConfiguration
        self.setupGuideStateService = setupGuideStateService
        self.authorizationService = authorizationService
        self.workoutReader = workoutReader
        self.syncCoordinator = syncCoordinator
        self.apiHealthChecker = apiHealthChecker
        self.homeService = homeService
        self.workoutService = workoutService
        self.planService = planService
        self.goalService = goalService
    }

    static func live() -> AppContainer {
        let runtimeConfiguration = LiveAppRuntimeConfigurationService()
        let setupGuideStateService = SetupGuideStateService()
        let authSession = InMemoryAuthSession(accessToken: LocalDevelopmentIdentity.bearerToken())
        let queueStore = InMemorySyncQueueStore()
        let authorizationService = HealthKitAuthorizationService()
        let workoutReader = HealthKitWorkoutReader(source: LiveHealthKitWorkoutSource())
        let apiHealthChecker = APIHealthCheckService()
        let syncCoordinator = WorkoutSyncCoordinator(
            apiClientProvider: {
                APIClient(
                    baseURL: runtimeConfiguration.resolveAPIBaseURL(),
                    authSession: authSession
                )
            },
            queueStore: queueStore
        )
        let store = DemoAppStore.demo()
        return AppContainer(
            authSession: authSession,
            queueStore: queueStore,
            runtimeConfiguration: runtimeConfiguration,
            setupGuideStateService: setupGuideStateService,
            authorizationService: authorizationService,
            workoutReader: workoutReader,
            syncCoordinator: syncCoordinator,
            apiHealthChecker: apiHealthChecker,
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
