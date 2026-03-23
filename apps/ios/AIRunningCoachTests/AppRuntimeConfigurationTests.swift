import XCTest
@testable import AIRunningCoach

final class AppRuntimeConfigurationTests: XCTestCase {
    func testResolveAPIBaseURLPrefersSavedOverrideValue() {
        let userDefaults = makeUserDefaults()
        userDefaults.set("http://192.168.1.20:8000", forKey: AppRuntimeConfiguration.apiBaseURLOverrideKey)

        let resolved = AppRuntimeConfiguration.resolveAPIBaseURL(
            environment: ["AIR_RUNNING_COACH_API_BASE_URL": "http://192.168.1.20:8000"],
            infoDictionary: ["AIRunningCoachAPIBaseURL": "http://127.0.0.1:8000"],
            userDefaults: userDefaults
        )

        XCTAssertEqual(resolved.absoluteString, "http://192.168.1.20:8000")
    }

    func testResolveAPIBaseURLPrefersEnvironmentValue() {
        let resolved = AppRuntimeConfiguration.resolveAPIBaseURL(
            environment: ["AIR_RUNNING_COACH_API_BASE_URL": "http://192.168.1.20:8000"],
            infoDictionary: ["AIRunningCoachAPIBaseURL": "http://127.0.0.1:8000"],
            userDefaults: makeUserDefaults()
        )

        XCTAssertEqual(resolved.absoluteString, "http://192.168.1.20:8000")
    }

    func testResolveAPIBaseURLFallsBackToInfoDictionary() {
        let resolved = AppRuntimeConfiguration.resolveAPIBaseURL(
            environment: [:],
            infoDictionary: ["AIRunningCoachAPIBaseURL": "http://10.0.0.8:8000"],
            userDefaults: makeUserDefaults()
        )

        XCTAssertEqual(resolved.absoluteString, "http://10.0.0.8:8000")
    }

    func testSaveAPIBaseURLOverridePersistsNormalizedValue() throws {
        let userDefaults = makeUserDefaults()

        let resolved = try AppRuntimeConfiguration.saveAPIBaseURLOverride(
            "  http://192.168.1.30:9000  ",
            userDefaults: userDefaults
        )

        XCTAssertEqual(resolved.absoluteString, "http://192.168.1.30:9000")
        XCTAssertEqual(
            userDefaults.string(forKey: AppRuntimeConfiguration.apiBaseURLOverrideKey),
            "http://192.168.1.30:9000"
        )
    }

    func testSaveAPIBaseURLOverrideRejectsInvalidValue() {
        let userDefaults = makeUserDefaults()

        XCTAssertThrowsError(
            try AppRuntimeConfiguration.saveAPIBaseURLOverride("not-a-url", userDefaults: userDefaults)
        ) { error in
            XCTAssertEqual(error as? AppRuntimeConfigurationError, .invalidAPIBaseURL)
        }
    }

    func testResetAPIBaseURLOverrideRemovesSavedValue() {
        let userDefaults = makeUserDefaults()
        userDefaults.set("http://192.168.1.20:8000", forKey: AppRuntimeConfiguration.apiBaseURLOverrideKey)

        let resolved = AppRuntimeConfiguration.resetAPIBaseURLOverride(
            environment: [:],
            infoDictionary: ["AIRunningCoachAPIBaseURL": "http://10.0.0.8:8000"],
            userDefaults: userDefaults
        )

        XCTAssertNil(userDefaults.string(forKey: AppRuntimeConfiguration.apiBaseURLOverrideKey))
        XCTAssertEqual(resolved.absoluteString, "http://10.0.0.8:8000")
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "AppRuntimeConfigurationTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
