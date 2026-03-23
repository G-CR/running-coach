import Foundation

enum LocalDevelopmentIdentity {
    private static let storedUserIDKey = "local_development_user_id"

    static func userID(userDefaults: UserDefaults = .standard) -> UUID {
        if let rawValue = userDefaults.string(forKey: storedUserIDKey),
           let existing = UUID(uuidString: rawValue) {
            return existing
        }

        let created = UUID()
        userDefaults.set(created.uuidString, forKey: storedUserIDKey)
        return created
    }

    static func bearerToken(userDefaults: UserDefaults = .standard) -> String {
        let header = ["alg": "none", "typ": "JWT"]
        let payload = ["sub": userID(userDefaults: userDefaults).uuidString]
        return "\(base64url(header)).\(base64url(payload))."
    }

    private static func base64url(_ value: [String: String]) -> String {
        let data = try? JSONSerialization.data(withJSONObject: value, options: [])
        let encoded = (data ?? Data()).base64EncodedString()
        return encoded
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
