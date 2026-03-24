import Foundation

enum APIHealthCheckError: Error, Equatable {
    case network
    case invalidResponse
    case unhealthy
}

protocol APIHealthChecking: Sendable {
    func checkHealth(baseURL: URL) async throws
}

final class APIHealthCheckService: APIHealthChecking, @unchecked Sendable {
    static let mockHealthyLaunchArgument = "UITest.MockAPIHealthy"

    private let session: URLSessioning
    private let launchArguments: [String]

    init(
        session: URLSessioning = URLSession.shared,
        launchArguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.session = session
        self.launchArguments = launchArguments
    }

    func checkHealth(baseURL: URL) async throws {
        if launchArguments.contains(Self.mockHealthyLaunchArgument) {
            return
        }

        let request = URLRequest(url: baseURL.appending(path: "health"))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIHealthCheckError.network
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIHealthCheckError.invalidResponse
        }

        let payload = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        guard payload?["status"] == "ok" else {
            throw APIHealthCheckError.unhealthy
        }
    }
}
