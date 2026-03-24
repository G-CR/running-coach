import SwiftUI

struct SetupGuideView: View {
    enum Step: Int, CaseIterable {
        case healthKit
        case api
        case sync

        var title: String {
            switch self {
            case .healthKit:
                return "授权 HealthKit"
            case .api:
                return "检查 API"
            case .sync:
                return "首次同步"
            }
        }

        var description: String {
            switch self {
            case .healthKit:
                return "先拿到跑步数据读取权限，后续分析和计划调整才有基础。"
            case .api:
                return "确认手机当前指向的 API 地址正确，并且能连到 Mac mini 上的本地服务。"
            case .sync:
                return "完成第一次跑步同步，把历史训练带进分析链路。"
            }
        }

        var primaryActionTitle: String {
            self == .sync ? "完成引导" : "下一步"
        }

        var requirementText: String? {
            switch self {
            case .healthKit:
                return "完成 HealthKit 授权后，才能继续下一步。"
            case .api:
                return "只有 API 检测通过后，才能进入第 3 步。"
            case .sync:
                return "至少完成一次同步尝试后，才能结束引导。"
            }
        }
    }

    @ObservedObject var viewModel: GoalSettingsViewModel
    let closeGuide: () -> Void

    @State private var currentStep: Step = .healthKit

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("首次设置")
                        .font(.largeTitle.bold())
                        .accessibilityIdentifier("setup.guide.title")
                    Text("步骤 \(currentStep.rawValue + 1) / \(Step.allCases.count)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(currentStep.title)
                        .font(.title2.bold())
                    Text(currentStep.description)
                        .foregroundStyle(.secondary)
                    if let requirementText = currentStep.requirementText {
                        Text(requirementText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Group {
                    switch currentStep {
                    case .healthKit:
                        healthKitStep
                    case .api:
                        apiStep
                    case .sync:
                        syncStep
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))

                Spacer()

                HStack {
                    if currentStep == .sync && viewModel.hasAttemptedInitialSync {
                        Button("稍后同步", action: closeGuide)
                            .accessibilityIdentifier("setup.guide.skip")
                    }
                    Spacer()
                    Button(currentStep.primaryActionTitle, action: advance)
                        .disabled(!canAdvance)
                        .accessibilityIdentifier("setup.guide.primary")
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.load()
            }
        }
        .interactiveDismissDisabled()
    }

    private var healthKitStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前状态：\(viewModel.healthKitStatus)")
            Button(viewModel.isAuthorizing ? "授权中..." : "请求 HealthKit 授权") {
                Task { await viewModel.requestHealthKitAuthorization() }
            }
            .disabled(viewModel.isAuthorizing)
        }
    }

    private var apiStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("http://192.168.1.20:8000", text: $viewModel.apiBaseURLText)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .autocorrectionDisabled()
            Text("当前 API：\(viewModel.apiBaseURLText)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Button("保存 API 地址") {
                    Task { await viewModel.saveAPIBaseURL() }
                }
                .accessibilityIdentifier("setup.guide.api.save")
                Button(viewModel.isCheckingAPIConnectivity ? "检测中..." : "检测 API 连通性") {
                    Task { await viewModel.checkAPIConnectivity() }
                }
                .disabled(viewModel.isCheckingAPIConnectivity)
                .accessibilityIdentifier("setup.guide.api.check")
            }
            if !viewModel.apiBaseURLStatus.isEmpty {
                Text(viewModel.apiBaseURLStatus)
                    .font(.footnote)
                    .foregroundStyle(viewModel.apiBaseURLHasError ? .red : .secondary)
            }
            if !viewModel.apiConnectivityStatus.isEmpty {
                Text(viewModel.apiConnectivityStatus)
                    .font(.footnote)
                    .foregroundStyle(viewModel.apiConnectivityHasError ? .red : .secondary)
            }
        }
    }

    private var syncStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("同步状态：\(viewModel.syncStatus)")
                .accessibilityIdentifier("setup.guide.sync.status")
            Button(viewModel.isSyncing ? "同步中..." : "同步最近跑步") {
                Task { await viewModel.syncRecentWorkouts() }
            }
            .disabled(viewModel.isSyncing)
            .accessibilityIdentifier("setup.guide.sync.action")
        }
    }

    private var canAdvance: Bool {
        switch currentStep {
        case .healthKit:
            return viewModel.isHealthKitAuthorized
        case .api:
            return viewModel.isAPIConnectivityConfirmed
        case .sync:
            return viewModel.hasAttemptedInitialSync
        }
    }

    private func advance() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else {
            closeGuide()
            return
        }
        currentStep = nextStep
    }
}
