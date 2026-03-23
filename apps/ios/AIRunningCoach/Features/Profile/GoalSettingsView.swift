import SwiftUI

@MainActor
final class GoalSettingsViewModel: ObservableObject {
    @Published var goalType = ""
    @Published var targetText = ""
    @Published var weeklyRunDays = 4.0
    @Published private(set) var healthKitStatus = ""
    @Published private(set) var syncStatus = ""
    @Published var aiPermissionEnabled = true

    private let goalService: GoalServing
    private let authorizationStatusModel: AuthorizationStatusModel

    init(goalService: GoalServing, authorizationStatusModel: AuthorizationStatusModel) {
        self.goalService = goalService
        self.authorizationStatusModel = authorizationStatusModel
    }

    func load() async {
        let data = await goalService.fetchGoal()
        goalType = data.goalType
        targetText = data.targetText
        weeklyRunDays = Double(data.weeklyRunDays)
        syncStatus = data.syncStatus
        aiPermissionEnabled = data.aiPermissionEnabled
        healthKitStatus = authorizationStatusModel.detail
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
                Toggle("允许 AI 分析", isOn: $viewModel.aiPermissionEnabled)
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
