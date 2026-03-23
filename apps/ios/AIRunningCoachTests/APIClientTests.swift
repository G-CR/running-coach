import Foundation
import XCTest
@testable import AIRunningCoach

final class APIClientTests: XCTestCase {
    func testImportWorkoutSendsBearerTokenAndPayload() async throws {
        let session = URLSessionStub(
            responseData: """
            {"workout_id":"workout-1","deduplicated":false,"analysis_job_id":"job-1"}
            """.data(using: .utf8)!
        )
        let authSession = InMemoryAuthSession(accessToken: "token-123")
        let sut = APIClient(
            baseURL: URL(string: "https://example.com")!,
            session: session,
            authSession: authSession
        )

        let response = try await sut.importWorkout(.fixture())

        XCTAssertEqual(response.workoutID, "workout-1")
        XCTAssertEqual(session.lastRequest?.url?.absoluteString, "https://example.com/v1/workouts/import")
        XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")
        XCTAssertTrue(String(data: try XCTUnwrap(session.lastRequest?.httpBody), encoding: .utf8)?.contains("source_workout_id") == true)
    }
}
