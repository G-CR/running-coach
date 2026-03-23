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
    @Published private(set) var isCheckingAPIConnectivity = false
    @Published var apiBaseURLText = ""
    @Published private(set) var apiBaseURLStatus = ""
    @Published private(set) var apiBaseURLHasError = false
    @Published private(set) var apiConnectivityStatus = ""
    @Published private(set) var apiConnectivityHasError = false

    private let goalService: GoalServing
    private let authorizationService: HealthKitAuthorizationProviding
    private let workoutReader: WorkoutImportReading
    private let syncCoordinator: WorkoutSyncCoordinating
    private let userID: UUID
    private let runtimeConfiguration: AppRuntimeConfigurationServing
    private let apiHealthChecker: APIHealthChecking

    init(
        goalService: GoalServing,
        authorizationService: HealthKitAuthorizationProviding,
        workoutReader: WorkoutImportReading,
        syncCoordinator: WorkoutSyncCoordinating,
        userID: UUID,
        runtimeConfiguration: AppRuntimeConfigurationServing,
        apiHealthChecker: APIHealthChecking
    ) {
        self.goalService = goalService
        self.authorizationService = authorizationService
        self.workoutReader = workoutReader
        self.syncCoordinator = syncCoordinator
        self.userID = userID
        self.runtimeConfiguration = runtimeConfiguration
        self.apiHealthChecker = apiHealthChecker
    }

    func load() async {
        let data = await goalService.fetchGoal()
        goalType = data.goalType
        targetText = data.targetText
        weeklyRunDays = Double(data.weeklyRunDays)
        syncStatus = data.syncStatus
        aiPermissionEnabled = data.aiPermissionEnabled
        healthKitStatus = authorizationService.currentStatus().description
        apiBaseURLText = runtimeConfiguration.resolveAPIBaseURL().absoluteString
        apiBaseURLStatus = ""
        apiBaseURLHasError = false
        apiConnectivityStatus = ""
        apiConnectivityHasError = false
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

    func saveAPIBaseURL() async {
        do {
            let resolvedURL = try runtimeConfiguration.saveAPIBaseURLOverride(apiBaseURLText)
            apiBaseURLText = resolvedURL.absoluteString
            apiBaseURLStatus = "API 地址已更新"
            apiBaseURLHasError = false
        } catch AppRuntimeConfigurationError.invalidAPIBaseURL {
            apiBaseURLStatus = "请输入有效的 http(s) API 地址"
            apiBaseURLHasError = true
        } catch {
            apiBaseURLStatus = "API 地址保存失败"
            apiBaseURLHasError = true
        }
    }

    func resetAPIBaseURL() async {
        let resolvedURL = runtimeConfiguration.resetAPIBaseURLOverride()
        apiBaseURLText = resolvedURL.absoluteString
        apiBaseURLStatus = "已恢复默认 API 地址"
        apiBaseURLHasError = false
    }

    func checkAPIConnectivity() async {
        isCheckingAPIConnectivity = true
        defer { isCheckingAPIConnectivity = false }

        do {
            let resolvedURL = try runtimeConfiguration.validateAPIBaseURL(apiBaseURLText)
            try await apiHealthChecker.checkHealth(baseURL: resolvedURL)
            apiConnectivityStatus = "API 连通正常"
            apiConnectivityHasError = false
        } catch AppRuntimeConfigurationError.invalidAPIBaseURL {
            apiConnectivityStatus = "请输入有效的 http(s) API 地址"
            apiConnectivityHasError = true
        } catch {
            apiConnectivityStatus = "无法连接到 API，请检查地址和服务状态"
            apiConnectivityHasError = true
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
    let reopenSetupGuide: () -> Void

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
                TextField("http://192.168.1.20:8000", text: $viewModel.apiBaseURLText)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                Text("当前 API：\(viewModel.apiBaseURLText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if !viewModel.apiBaseURLStatus.isEmpty {
                    Text(viewModel.apiBaseURLStatus)
                        .font(.footnote)
                        .foregroundStyle(viewModel.apiBaseURLHasError ? .red : .secondary)
                }
                Button("保存 API 地址") {
                    Task { await viewModel.saveAPIBaseURL() }
                }
                Button(viewModel.isCheckingAPIConnectivity ? "检测中..." : "检测 API 连通性") {
                    Task { await viewModel.checkAPIConnectivity() }
                }
                .disabled(viewModel.isCheckingAPIConnectivity)
                Button("恢复默认地址") {
                    Task { await viewModel.resetAPIBaseURL() }
                }
                if !viewModel.apiConnectivityStatus.isEmpty {
                    Text(viewModel.apiConnectivityStatus)
                        .font(.footnote)
                        .foregroundStyle(viewModel.apiConnectivityHasError ? .red : .secondary)
                }
                Button(action: reopenSetupGuide) {
                    Label("重新打开首次引导", systemImage: "sparkles")
                }
                .accessibilityIdentifier("profile.reopenSetupGuide")
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
