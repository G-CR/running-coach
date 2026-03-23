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
    private let session: URLSessioning

    init(session: URLSessioning = URLSession.shared) {
        self.session = session
    }

    func checkHealth(baseURL: URL) async throws {
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
