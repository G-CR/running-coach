import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    enum Section: Equatable {
        case nextWorkout
        case reason
        case latestWorkout
        case planPreview
        case todos
    }

    @Published private(set) var nextWorkout: NextWorkoutCard?
    @Published private(set) var reasonSummary = ""
    @Published private(set) var latestWorkout: LatestWorkoutSummaryCard?
    @Published private(set) var planChangeSummary: PlanChangeSummaryCard?
    @Published private(set) var todos: HomeTodosCard?
    @Published private(set) var sections: [Section] = []

    private let service: HomeServing

    init(service: HomeServing) {
        self.service = service
    }

    func load() async {
        let data = await service.fetchHome()
        nextWorkout = data.nextWorkout
        reasonSummary = data.reasonSummary
        latestWorkout = data.latestWorkout
        planChangeSummary = data.planChangeSummary
        todos = data.todos
        sections = [.nextWorkout, .reason, .latestWorkout, .planPreview, .todos]
    }
}
