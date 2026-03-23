import Foundation

enum WorkoutTypeCode: String, Codable, Equatable, Sendable {
    case recoveryRun = "recovery_run"
    case easyRun = "easy_run"
    case longRun = "long_run"
    case tempoRun = "tempo_run"
    case rest = "rest"

    var title: String {
        switch self {
        case .recoveryRun:
            return "Recovery Run"
        case .easyRun:
            return "Easy Run"
        case .longRun:
            return "Long Run"
        case .tempoRun:
            return "Tempo Run"
        case .rest:
            return "Rest"
        }
    }
}

struct NextWorkoutCard: Equatable, Sendable {
    let type: String
    let title: String
    let durationText: String
    let intensityText: String
    let dateText: String
    let isAdjusted: Bool
}

struct LatestWorkoutSummaryCard: Equatable, Sendable {
    let id: UUID
    let title: String
    let distanceText: String
    let durationText: String
    let paceText: String
    let heartRateText: String
    let analysisTag: String
}

struct PlanChangeSummaryCard: Equatable, Sendable {
    let changedItems: Int
    let summaryText: String
}

struct HomeTodosCard: Equatable, Sendable {
    let needsFeedback: Bool
    let syncPending: Bool
    let analysisPending: Bool

    var feedbackStatusText: String {
        needsFeedback ? "补充最近一次训练反馈" : "主观反馈已完成"
    }
}

struct HomeScreenData: Equatable, Sendable {
    let nextWorkout: NextWorkoutCard
    let reasonSummary: String
    let latestWorkout: LatestWorkoutSummaryCard
    let planChangeSummary: PlanChangeSummaryCard
    let todos: HomeTodosCard

    static func fixture(nextWorkoutType: String = "recovery_run", needsFeedback: Bool = true) -> HomeScreenData {
        HomeScreenData(
            nextWorkout: NextWorkoutCard(
                type: nextWorkoutType,
                title: nextWorkoutType == "recovery_run" ? "Recovery Run" : "Easy Run",
                durationText: "35 min",
                intensityText: "Z1-Z2",
                dateText: "Tomorrow",
                isAdjusted: true
            ),
            reasonSummary: "High fatigue after the latest run, so the next session stays easy.",
            latestWorkout: LatestWorkoutSummaryCard(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000111")!,
                title: "Latest 5K Run",
                distanceText: "5.0 km",
                durationText: "30 min",
                paceText: "6:00 /km",
                heartRateText: "148 bpm",
                analysisTag: "Protective"
            ),
            planChangeSummary: PlanChangeSummaryCard(
                changedItems: 3,
                summaryText: "The next 7 days keep volume lower and delay quality work."
            ),
            todos: HomeTodosCard(
                needsFeedback: needsFeedback,
                syncPending: false,
                analysisPending: false
            )
        )
    }
}

struct WorkoutListItemData: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let dateText: String
    let distanceText: String
    let durationText: String
    let paceText: String
    let heartRateText: String
}

struct WorkoutMetric: Equatable, Sendable {
    let label: String
    let value: String
}

struct LapSummaryRow: Identifiable, Equatable, Sendable {
    let id = UUID()
    let label: String
    let paceText: String
    let heartRateText: String
}

struct DistributionSummary: Identifiable, Equatable, Sendable {
    let id = UUID()
    let label: String
    let value: String
}

struct SubmittedFeedbackSummary: Equatable, Sendable {
    let tags: [String]
    let note: String
}

struct WorkoutImpactSummary: Equatable, Sendable {
    let nextWorkoutText: String
    let weekPlanText: String
}

struct WorkoutDetailData: Equatable, Sendable {
    let id: UUID
    let title: String
    let coreSummary: [WorkoutMetric]
    let coachConclusion: String
    let lapRows: [LapSummaryRow]
    let distributions: [DistributionSummary]
    let runningForm: [WorkoutMetric]
    let feedback: SubmittedFeedbackSummary?
    let impact: WorkoutImpactSummary
}

struct PlanDayItem: Identifiable, Equatable, Sendable {
    let id = UUID()
    let dateText: String
    let workoutType: String
    let durationText: String
    let intensityText: String
    let changed: Bool
    let changeReason: String?
}

struct PlanScreenData: Equatable, Sendable {
    let windowTitle: String
    let version: Int
    let items: [PlanDayItem]

    static func fixture() -> PlanScreenData {
        PlanScreenData(
            windowTitle: "Next 7 Days",
            version: 1,
            items: [
                PlanDayItem(dateText: "Mon", workoutType: "Recovery Run", durationText: "35 min", intensityText: "Z1-Z2", changed: true, changeReason: "Protect recovery after high fatigue"),
                PlanDayItem(dateText: "Tue", workoutType: "Rest", durationText: "-", intensityText: "Rest", changed: true, changeReason: "Keep load conservative"),
                PlanDayItem(dateText: "Wed", workoutType: "Easy Run", durationText: "40 min", intensityText: "Z2", changed: true, changeReason: "Delay quality session"),
                PlanDayItem(dateText: "Thu", workoutType: "Rest", durationText: "-", intensityText: "Rest", changed: false, changeReason: nil),
                PlanDayItem(dateText: "Fri", workoutType: "Easy Run", durationText: "45 min", intensityText: "Z2", changed: false, changeReason: nil),
                PlanDayItem(dateText: "Sat", workoutType: "Rest", durationText: "-", intensityText: "Rest", changed: false, changeReason: nil),
                PlanDayItem(dateText: "Sun", workoutType: "Long Run", durationText: "75 min", intensityText: "Z2", changed: false, changeReason: nil),
            ]
        )
    }
}

struct GoalSettingsData: Equatable, Sendable {
    let goalType: String
    let targetText: String
    let weeklyRunDays: Int
    let healthKitStatus: String
    let syncStatus: String
    let aiPermissionEnabled: Bool
}

struct FeedbackDraft: Equatable, Sendable {
    let rpe: Int
    let fatigue: Int
    let soreness: Int
    let selectedTags: [String]
    let note: String

    static func fixture() -> FeedbackDraft {
        FeedbackDraft(
            rpe: 7,
            fatigue: 4,
            soreness: 2,
            selectedTags: ["偏吃力", "腿沉"],
            note: "前半程轻松，后半程腿有点重。"
        )
    }
}
