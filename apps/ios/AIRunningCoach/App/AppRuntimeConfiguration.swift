import Foundation

enum AppRuntimeConfigurationError: Error, Equatable {
    case invalidAPIBaseURL
}

protocol AppRuntimeConfigurationServing: Sendable {
    func resolveAPIBaseURL() -> URL
    func validateAPIBaseURL(_ rawValue: String) throws -> URL
    func saveAPIBaseURLOverride(_ rawValue: String) throws -> URL
    func resetAPIBaseURLOverride() -> URL
}

struct LiveAppRuntimeConfigurationService: AppRuntimeConfigurationServing {
    func resolveAPIBaseURL() -> URL {
        AppRuntimeConfiguration.resolveAPIBaseURL()
    }

    func validateAPIBaseURL(_ rawValue: String) throws -> URL {
        try AppRuntimeConfiguration.validateAPIBaseURL(rawValue)
    }

    func saveAPIBaseURLOverride(_ rawValue: String) throws -> URL {
        try AppRuntimeConfiguration.saveAPIBaseURLOverride(rawValue)
    }

    func resetAPIBaseURLOverride() -> URL {
        AppRuntimeConfiguration.resetAPIBaseURLOverride()
    }
}

enum AppRuntimeConfiguration {
    static let apiBaseURLInfoKey = "AIRunningCoachAPIBaseURL"
    static let apiBaseURLEnvironmentKey = "AIR_RUNNING_COACH_API_BASE_URL"
    static let apiBaseURLOverrideKey = "air_running_coach_api_base_url_override"
    static let defaultAPIBaseURL = URL(string: "http://127.0.0.1:8000")!

    static func resolveAPIBaseURL(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:],
        userDefaults: UserDefaults = .standard
    ) -> URL {
        if let rawValue = userDefaults.string(forKey: apiBaseURLOverrideKey),
           let url = normalizedAPIBaseURL(rawValue) {
            return url
        }
        if let rawValue = environment[apiBaseURLEnvironmentKey], let url = normalizedAPIBaseURL(rawValue) {
            return url
        }
        if let rawValue = infoDictionary[apiBaseURLInfoKey] as? String, let url = normalizedAPIBaseURL(rawValue) {
            return url
        }
        return defaultAPIBaseURL
    }

    static func saveAPIBaseURLOverride(
        _ rawValue: String,
        userDefaults: UserDefaults = .standard
    ) throws -> URL {
        let url = try validateAPIBaseURL(rawValue)
        userDefaults.set(url.absoluteString, forKey: apiBaseURLOverrideKey)
        return url
    }

    static func resetAPIBaseURLOverride(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:],
        userDefaults: UserDefaults = .standard
    ) -> URL {
        userDefaults.removeObject(forKey: apiBaseURLOverrideKey)
        return resolveAPIBaseURL(
            environment: environment,
            infoDictionary: infoDictionary,
            userDefaults: userDefaults
        )
    }

    static func validateAPIBaseURL(_ rawValue: String) throws -> URL {
        guard let url = normalizedAPIBaseURL(rawValue) else {
            throw AppRuntimeConfigurationError.invalidAPIBaseURL
        }
        return url
    }

    private static func normalizedAPIBaseURL(_ rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }
}
