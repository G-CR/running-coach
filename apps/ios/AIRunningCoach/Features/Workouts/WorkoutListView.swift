import SwiftUI

@MainActor
final class WorkoutListViewModel: ObservableObject {
    @Published private(set) var items: [WorkoutListItemData] = []
    private let service: WorkoutServing

    init(service: WorkoutServing) {
        self.service = service
    }

    func load() async {
        items = await service.fetchWorkouts()
    }
}

struct WorkoutListView: View {
    @StateObject private var viewModel: WorkoutListViewModel
    private let service: WorkoutServing

    init(service: WorkoutServing) {
        self.service = service
        _viewModel = StateObject(wrappedValue: WorkoutListViewModel(service: service))
    }

    var body: some View {
        List(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
            NavigationLink(
                destination: WorkoutDetailView(
                    viewModel: WorkoutDetailViewModel(workoutID: item.id, service: service),
                    feedbackService: service
                )
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                    Text("\(item.dateText) · \(item.distanceText) · \(item.durationText)")
                    Text("\(item.paceText) · \(item.heartRateText)")
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier(index == 0 ? "workout.list.first" : "workout.list.\(index)")
        }
        .navigationTitle("训练")
        .task {
            await viewModel.load()
        }
    }
}
