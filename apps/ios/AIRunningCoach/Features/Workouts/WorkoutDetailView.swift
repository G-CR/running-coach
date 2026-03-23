import SwiftUI

@MainActor
final class WorkoutDetailViewModel: ObservableObject {
    @Published private(set) var detail: WorkoutDetailData?

    private let workoutID: UUID
    private let service: WorkoutServing

    init(workoutID: UUID, service: WorkoutServing) {
        self.workoutID = workoutID
        self.service = service
    }

    func load() async {
        detail = await service.fetchWorkoutDetail(id: workoutID)
    }
}

struct WorkoutDetailView: View {
    @StateObject var viewModel: WorkoutDetailViewModel
    let feedbackService: WorkoutServing

    @State private var showingFeedback = false

    var body: some View {
        ScrollView {
            if let detail = viewModel.detail {
                VStack(alignment: .leading, spacing: 16) {
                    section("核心汇总") {
                        ForEach(detail.coreSummary, id: \.label) { item in
                            Text("\(item.label): \(item.value)")
                        }
                    }

                    section("教练结论") {
                        Text(detail.coachConclusion)
                    }

                    section("分段表现") {
                        ForEach(detail.lapRows) { row in
                            Text("\(row.label): \(row.paceText) · \(row.heartRateText)")
                        }
                    }

                    section("分布") {
                        ForEach(detail.distributions) { distribution in
                            Text("\(distribution.label): \(distribution.value)")
                        }
                    }

                    section("动作指标") {
                        ForEach(detail.runningForm, id: \.label) { item in
                            Text("\(item.label): \(item.value)")
                        }
                    }

                    section("主观反馈") {
                        if let feedback = detail.feedback {
                            Text("已提交反馈")
                            Text(feedback.tags.joined(separator: " · "))
                            Text(feedback.note)
                        } else {
                            Button("补训练反馈") {
                                showingFeedback = true
                            }
                            .accessibilityIdentifier("workout.detail.feedback")
                        }
                    }

                    section("对计划的影响") {
                        Text(detail.impact.nextWorkoutText)
                        Text(detail.impact.weekPlanText)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(viewModel.detail?.title ?? "训练详情")
        .task {
            await viewModel.load()
        }
        .navigationDestination(isPresented: $showingFeedback) {
            if let detail = viewModel.detail {
                PostWorkoutFeedbackView(
                    viewModel: PostWorkoutFeedbackViewModel(workoutID: detail.id, service: feedbackService)
                )
            }
        }
        .onAppear {
            Task { await viewModel.load() }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
