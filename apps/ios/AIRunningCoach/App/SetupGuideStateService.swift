import Foundation

protocol SetupGuideStateServing: Sendable {
    func shouldPresentGuide() -> Bool
    func markGuideSeen()
}

struct SetupGuideStateService: SetupGuideStateServing {
    static let seenKey = "air_running_coach_setup_guide_seen"
    static let resetLaunchArgument = "UITest.ResetSetupGuide"
    static let skipLaunchArgument = "UITest.SkipSetupGuide"

    private let userDefaults: UserDefaults

    init(
        userDefaults: UserDefaults = .standard,
        launchArguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.userDefaults = userDefaults
        Self.applyLaunchArguments(launchArguments, userDefaults: userDefaults)
    }

    func shouldPresentGuide() -> Bool {
        !userDefaults.bool(forKey: Self.seenKey)
    }

    func markGuideSeen() {
        userDefaults.set(true, forKey: Self.seenKey)
    }

    private static func applyLaunchArguments(_ launchArguments: [String], userDefaults: UserDefaults) {
        if launchArguments.contains(resetLaunchArgument) {
            userDefaults.removeObject(forKey: seenKey)
        }
        if launchArguments.contains(skipLaunchArgument) {
            userDefaults.set(true, forKey: seenKey)
        }
    }
}
