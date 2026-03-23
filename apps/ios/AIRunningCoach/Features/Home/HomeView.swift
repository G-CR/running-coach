import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    let openWorkouts: () -> Void
    let openPlan: () -> Void
    let reloadToken: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("今天怎么跑")
                    .font(.largeTitle.bold())

                if let nextWorkout = viewModel.nextWorkout {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("下一练")
                            .font(.headline)
                        Text(nextWorkout.title)
                            .font(.title2.bold())
                            .accessibilityIdentifier("home.nextWorkout.title")
                        Text("\(nextWorkout.durationText) · \(nextWorkout.intensityText)")
                        Text(nextWorkout.dateText)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }

                if !viewModel.reasonSummary.isEmpty {
                    card(title: "为什么这样安排", value: viewModel.reasonSummary)
                }

                if let latestWorkout = viewModel.latestWorkout {
                    Button(action: openWorkouts) {
                        card(
                            title: latestWorkout.title,
                            value: "\(latestWorkout.distanceText) · \(latestWorkout.durationText)\n\(latestWorkout.paceText) · \(latestWorkout.heartRateText)"
                        )
                    }
                    .buttonStyle(.plain)
                }

                if let planChangeSummary = viewModel.planChangeSummary {
                    Button(action: openPlan) {
                        card(
                            title: "未来 7 天变化",
                            value: "\(planChangeSummary.changedItems) 项调整\n\(planChangeSummary.summaryText)"
                        )
                    }
                    .buttonStyle(.plain)
                }

                if let todos = viewModel.todos {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("待办")
                            .font(.headline)
                        if todos.needsFeedback {
                            Text(todos.feedbackStatusText)
                        } else {
                            Text("主观反馈已完成")
                                .accessibilityIdentifier("home.todo.feedback.complete")
                        }
                        if todos.syncPending {
                            Text("还有训练待同步")
                        }
                        if todos.analysisPending {
                            Text("分析进行中")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding()
        }
        .navigationTitle("首页")
        .task(id: reloadToken) {
            await viewModel.load()
        }
    }

    private func card(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
