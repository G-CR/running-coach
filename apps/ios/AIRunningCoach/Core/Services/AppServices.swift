import Foundation

@MainActor
protocol HomeServing: AnyObject {
    func fetchHome() async -> HomeScreenData
}

@MainActor
protocol WorkoutServing: AnyObject {
    func fetchWorkouts() async -> [WorkoutListItemData]
    func fetchWorkoutDetail(id: UUID) async -> WorkoutDetailData?
    func submitFeedback(workoutID: UUID, draft: FeedbackDraft) async
}

@MainActor
protocol PlanServing: AnyObject {
    func fetchPlan(days: Int) async -> PlanScreenData
}

@MainActor
protocol GoalServing: AnyObject {
    func fetchGoal() async -> GoalSettingsData
    func updateGoal(_ goal: GoalSettingsData) async
}

@MainActor
final class DemoAppStore {
    var home: HomeScreenData
    var workouts: [WorkoutListItemData]
    var workoutDetails: [UUID: WorkoutDetailData]
    var plan: PlanScreenData
    var goal: GoalSettingsData

    init(
        home: HomeScreenData = .fixture(),
        workouts: [WorkoutListItemData],
        workoutDetails: [UUID: WorkoutDetailData],
        plan: PlanScreenData = .fixture(),
        goal: GoalSettingsData
    ) {
        self.home = home
        self.workouts = workouts
        self.workoutDetails = workoutDetails
        self.plan = plan
        self.goal = goal
    }

    static func demo() -> DemoAppStore {
        let workoutID = UUID(uuidString: "00000000-0000-0000-0000-000000000111")!
        let detail = WorkoutDetailData(
            id: workoutID,
            title: "Morning 5K",
            coreSummary: [
                WorkoutMetric(label: "Distance", value: "5.0 km"),
                WorkoutMetric(label: "Duration", value: "30 min"),
                WorkoutMetric(label: "Avg Pace", value: "6:00 /km"),
                WorkoutMetric(label: "Avg HR", value: "148 bpm"),
            ],
            coachConclusion: "Protective mode: prioritize recovery before quality work.",
            lapRows: [
                LapSummaryRow(label: "Lap 1", paceText: "5:58 /km", heartRateText: "144 bpm"),
                LapSummaryRow(label: "Lap 2", paceText: "6:02 /km", heartRateText: "149 bpm"),
            ],
            distributions: [
                DistributionSummary(label: "Heart Rate", value: "Z2 40% / Z3 60%"),
                DistributionSummary(label: "Pace", value: "Easy 100%"),
            ],
            runningForm: [
                WorkoutMetric(label: "Cadence", value: "168 spm"),
                WorkoutMetric(label: "Stride", value: "1.02 m"),
                WorkoutMetric(label: "Power", value: "245 W"),
            ],
            feedback: nil,
            impact: WorkoutImpactSummary(
                nextWorkoutText: "Next: Recovery Run, 35 min, Z1-Z2.",
                weekPlanText: "Delay quality work and keep weekly volume conservative."
            )
        )

        return DemoAppStore(
            workouts: [
                WorkoutListItemData(
                    id: workoutID,
                    title: "Morning 5K",
                    dateText: "Today",
                    distanceText: "5.0 km",
                    durationText: "30 min",
                    paceText: "6:00 /km",
                    heartRateText: "148 bpm"
                )
            ],
            workoutDetails: [workoutID: detail],
            goal: GoalSettingsData(
                goalType: "10K Improvement",
                targetText: "50:00 target time",
                weeklyRunDays: 4,
                healthKitStatus: "Authorized",
                syncStatus: "Up to date",
                aiPermissionEnabled: true
            )
        )
    }

    func submitFeedback(workoutID: UUID, draft: FeedbackDraft) {
        guard let detail = workoutDetails[workoutID] else {
            return
        }
        workoutDetails[workoutID] = WorkoutDetailData(
            id: detail.id,
            title: detail.title,
            coreSummary: detail.coreSummary,
            coachConclusion: detail.coachConclusion,
            lapRows: detail.lapRows,
            distributions: detail.distributions,
            runningForm: detail.runningForm,
            feedback: SubmittedFeedbackSummary(tags: draft.selectedTags, note: draft.note),
            impact: detail.impact
        )
        home = HomeScreenData.fixture(nextWorkoutType: home.nextWorkout.type, needsFeedback: false)
    }
}

@MainActor
final class DemoHomeService: HomeServing {
    private let store: DemoAppStore

    init(store: DemoAppStore) {
        self.store = store
    }

    func fetchHome() async -> HomeScreenData {
        store.home
    }
}

@MainActor
final class DemoWorkoutService: WorkoutServing {
    private let store: DemoAppStore

    init(store: DemoAppStore) {
        self.store = store
    }

    func fetchWorkouts() async -> [WorkoutListItemData] {
        store.workouts
    }

    func fetchWorkoutDetail(id: UUID) async -> WorkoutDetailData? {
        store.workoutDetails[id]
    }

    func submitFeedback(workoutID: UUID, draft: FeedbackDraft) async {
        store.submitFeedback(workoutID: workoutID, draft: draft)
    }
}

@MainActor
final class DemoPlanService: PlanServing {
    private let store: DemoAppStore

    init(store: DemoAppStore) {
        self.store = store
    }

    func fetchPlan(days: Int) async -> PlanScreenData {
        let items = Array(store.plan.items.prefix(days))
        return PlanScreenData(windowTitle: store.plan.windowTitle, version: store.plan.version, items: items)
    }
}

@MainActor
final class DemoGoalService: GoalServing {
    private let store: DemoAppStore

    init(store: DemoAppStore) {
        self.store = store
    }

    func fetchGoal() async -> GoalSettingsData {
        store.goal
    }

    func updateGoal(_ goal: GoalSettingsData) async {
        store.goal = goal
    }
}
