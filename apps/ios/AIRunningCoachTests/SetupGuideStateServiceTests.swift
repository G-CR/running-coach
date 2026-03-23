import XCTest
@testable import AIRunningCoach

final class SetupGuideStateServiceTests: XCTestCase {
    func testShouldPresentGuideOnFirstLaunch() {
        let userDefaults = makeUserDefaults()
        let sut = SetupGuideStateService(userDefaults: userDefaults)

        XCTAssertTrue(sut.shouldPresentGuide())
    }

    func testMarkGuideSeenStopsAutoPresentation() {
        let userDefaults = makeUserDefaults()
        let sut = SetupGuideStateService(userDefaults: userDefaults)

        sut.markGuideSeen()

        XCTAssertFalse(sut.shouldPresentGuide())
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "SetupGuideStateServiceTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
