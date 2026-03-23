import XCTest
@testable import AIRunningCoach

@MainActor
final class PlanViewModelTests: XCTestCase {
    func testPlanViewModelLoadsSevenDayItems() async throws {
        let service = PlanServiceStub(response: .fixture())
        let sut = PlanViewModel(service: service)

        await sut.load()

        XCTAssertEqual(sut.items.count, 7)
        XCTAssertEqual(sut.items.first?.workoutType, "Recovery Run")
    }
}
