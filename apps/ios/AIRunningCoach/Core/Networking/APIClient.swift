import Foundation

protocol URLSessioning: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessioning {}

enum APIClientError: Error, Equatable {
    case network
    case invalidResponse
    case server(Int)
}

protocol APIClientProtocol: Sendable {
    func importWorkout(_ workout: WorkoutImportPayload) async throws -> WorkoutImportResponse
}

final class APIClient: APIClientProtocol, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSessioning
    private let authSession: AuthSessioning

    init(
        baseURL: URL,
        session: URLSessioning = URLSession.shared,
        authSession: AuthSessioning
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authSession = authSession
    }

    func importWorkout(_ workout: WorkoutImportPayload) async throws -> WorkoutImportResponse {
        var request = URLRequest(url: baseURL.appending(path: "v1/workouts/import"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authSession.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(workout)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIClientError.network
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw APIClientError.server(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(WorkoutImportResponse.self, from: data)
        } catch {
            throw APIClientError.invalidResponse
        }
    }
}
