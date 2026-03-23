import XCTest
@testable import AIRunningCoach

final class AppRuntimeConfigurationTests: XCTestCase {
    func testResolveAPIBaseURLPrefersEnvironmentValue() {
        let resolved = AppRuntimeConfiguration.resolveAPIBaseURL(
            environment: ["AIR_RUNNING_COACH_API_BASE_URL": "http://192.168.1.20:8000"],
            infoDictionary: ["AIRunningCoachAPIBaseURL": "http://127.0.0.1:8000"]
        )

        XCTAssertEqual(resolved.absoluteString, "http://192.168.1.20:8000")
    }

    func testResolveAPIBaseURLFallsBackToInfoDictionary() {
        let resolved = AppRuntimeConfiguration.resolveAPIBaseURL(
            environment: [:],
            infoDictionary: ["AIRunningCoachAPIBaseURL": "http://10.0.0.8:8000"]
        )

        XCTAssertEqual(resolved.absoluteString, "http://10.0.0.8:8000")
    }
}
