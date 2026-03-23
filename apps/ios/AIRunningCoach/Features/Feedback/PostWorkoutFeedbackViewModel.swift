import Foundation

@MainActor
final class PostWorkoutFeedbackViewModel: ObservableObject {
    @Published var didSubmit = false

    private let workoutID: UUID
    private let service: WorkoutServing

    init(workoutID: UUID, service: WorkoutServing) {
        self.workoutID = workoutID
        self.service = service
    }

    func submit(_ draft: FeedbackDraft) async {
        await service.submitFeedback(workoutID: workoutID, draft: draft)
        didSubmit = true
    }
}
