import SwiftUI

@MainActor
final class GoalSettingsViewModel: ObservableObject {
    @Published var goalType = ""
    @Published var targetText = ""
    @Published var weeklyRunDays = 4.0
    @Published private(set) var healthKitStatus = ""
    @Published private(set) var syncStatus = ""
    @Published var aiPermissionEnabled = true
    @Published private(set) var isAuthorizing = false
    @Published private(set) var isSyncing = false
    @Published private(set) var apiBaseURLText = ""

    private let goalService: GoalServing
    private let authorizationService: HealthKitAuthorizationProviding
    private let workoutReader: WorkoutImportReading
    private let syncCoordinator: WorkoutSyncCoordinating
    private let userID: UUID

    init(
        goalService: GoalServing,
        authorizationService: HealthKitAuthorizationProviding,
        workoutReader: WorkoutImportReading,
        syncCoordinator: WorkoutSyncCoordinating,
        userID: UUID
    ) {
        self.goalService = goalService
        self.authorizationService = authorizationService
        self.workoutReader = workoutReader
        self.syncCoordinator = syncCoordinator
        self.userID = userID
    }

    func load() async {
        let data = await goalService.fetchGoal()
        goalType = data.goalType
        targetText = data.targetText
        weeklyRunDays = Double(data.weeklyRunDays)
        syncStatus = data.syncStatus
        aiPermissionEnabled = data.aiPermissionEnabled
        healthKitStatus = authorizationService.currentStatus().description
        apiBaseURLText = AppRuntimeConfiguration.resolveAPIBaseURL().absoluteString
    }

    func requestHealthKitAuthorization() async {
        isAuthorizing = true
        defer { isAuthorizing = false }

        do {
            let state = try await authorizationService.requestAuthorization()
            healthKitStatus = state.description
        } catch {
            healthKitStatus = "HealthKit 授权失败"
        }
    }

    func syncRecentWorkouts() async {
        guard authorizationService.currentStatus() == .authorized else {
            syncStatus = "请先完成 HealthKit 授权"
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let workouts = try await workoutReader.readWorkouts(userID: userID)
            for workout in workouts {
                try await syncCoordinator.sync(workout: workout)
            }
            syncStatus = workouts.isEmpty ? "没有发现新的跑步训练" : "已同步 \(workouts.count) 条跑步训练"
        } catch {
            syncStatus = "同步失败，请检查 API 地址和本地服务"
        }
    }

    func save() async {
        await goalService.updateGoal(
            GoalSettingsData(
                goalType: goalType,
                targetText: targetText,
                weeklyRunDays: Int(weeklyRunDays),
                healthKitStatus: healthKitStatus,
                syncStatus: syncStatus,
                aiPermissionEnabled: aiPermissionEnabled
            )
        )
    }
}

struct GoalSettingsView: View {
    @StateObject var viewModel: GoalSettingsViewModel

    var body: some View {
        Form {
            Section("目标") {
                TextField("目标类型", text: $viewModel.goalType)
                TextField("量化目标", text: $viewModel.targetText)
                Stepper("每周跑步 \(Int(viewModel.weeklyRunDays)) 天", value: $viewModel.weeklyRunDays, in: 1...7, step: 1)
            }

            Section("状态") {
                Text("HealthKit：\(viewModel.healthKitStatus)")
                Text("同步：\(viewModel.syncStatus)")
                Text("API：\(viewModel.apiBaseURLText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Toggle("允许 AI 分析", isOn: $viewModel.aiPermissionEnabled)
                Button(viewModel.isAuthorizing ? "授权中..." : "请求 HealthKit 授权") {
                    Task { await viewModel.requestHealthKitAuthorization() }
                }
                .disabled(viewModel.isAuthorizing)
                Button(viewModel.isSyncing ? "同步中..." : "同步最近跑步") {
                    Task { await viewModel.syncRecentWorkouts() }
                }
                .disabled(viewModel.isSyncing)
            }

            Button("保存目标") {
                Task { await viewModel.save() }
            }
        }
        .navigationTitle("我的")
        .task {
            await viewModel.load()
        }
    }
}
