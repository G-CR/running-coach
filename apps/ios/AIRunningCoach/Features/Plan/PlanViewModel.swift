import Foundation

@MainActor
final class PlanViewModel: ObservableObject {
    @Published private(set) var windowTitle = ""
    @Published private(set) var items: [PlanDayItem] = []

    private let service: PlanServing

    init(service: PlanServing) {
        self.service = service
    }

    func load(days: Int = 7) async {
        let data = await service.fetchPlan(days: days)
        windowTitle = data.windowTitle
        items = data.items
    }
}
