import XCTest
@testable import AIRunningCoach

@MainActor
final class PostWorkoutFeedbackViewModelTests: XCTestCase {
    func testFeedbackSubmissionRefreshesHome() async throws {
        let feedback = FeedbackServiceSpy()
        let sut = PostWorkoutFeedbackViewModel(workoutID: UUID(), service: feedback)

        await sut.submit(.fixture())

        XCTAssertTrue(feedback.didSubmit)
        XCTAssertTrue(sut.didSubmit)
    }
}
