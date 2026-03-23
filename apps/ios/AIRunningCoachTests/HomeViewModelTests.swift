import XCTest
@testable import AIRunningCoach

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testHomeViewModelShowsNextWorkoutFirst() async throws {
        let service = HomeServiceStub(response: .fixture(nextWorkoutType: "recovery_run"))
        let sut = HomeViewModel(service: service)

        await sut.load()

        XCTAssertEqual(sut.nextWorkout?.type, "recovery_run")
        XCTAssertEqual(sut.sections.first, .nextWorkout)
    }
}
