import Foundation

enum AppRuntimeConfiguration {
    static let apiBaseURLInfoKey = "AIRunningCoachAPIBaseURL"
    static let apiBaseURLEnvironmentKey = "AIR_RUNNING_COACH_API_BASE_URL"
    static let defaultAPIBaseURL = URL(string: "http://127.0.0.1:8000")!

    static func resolveAPIBaseURL(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) -> URL {
        if let rawValue = environment[apiBaseURLEnvironmentKey], let url = URL(string: rawValue) {
            return url
        }
        if let rawValue = infoDictionary[apiBaseURLInfoKey] as? String, let url = URL(string: rawValue) {
            return url
        }
        return defaultAPIBaseURL
    }
}
