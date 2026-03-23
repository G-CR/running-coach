import Foundation
@testable import AIRunningCoach

final class URLSessionStub: URLSessioning {
    private let responseData: Data
    private let statusCode: Int
    private let error: Error?
    private(set) var lastRequest: URLRequest?

    init(responseData: Data, statusCode: Int = 202, error: Error? = nil) {
        self.responseData = responseData
        self.statusCode = statusCode
        self.error = error
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let error {
            throw error
        }

        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responseData, response)
    }
}

final class APIClientStub: APIClientProtocol {
    let result: Result<WorkoutImportResponse, APIClientError>
    private(set) var importCallCount = 0

    init(result: Result<WorkoutImportResponse, APIClientError>) {
        self.result = result
    }

    func importWorkout(_ workout: WorkoutImportPayload) async throws -> WorkoutImportResponse {
        _ = workout
        importCallCount += 1
        return try result.get()
    }
}

struct HealthKitWorkoutSourceStub: HealthKitWorkoutSource {
    let records: [HealthKitWorkoutRecord]

    func readWorkouts(since anchor: Date?) async throws -> [HealthKitWorkoutRecord] {
        _ = anchor
        return records
    }
}

@MainActor
final class HomeServiceStub: HomeServing {
    let response: HomeScreenData

    init(response: HomeScreenData) {
        self.response = response
    }

    func fetchHome() async -> HomeScreenData {
        response
    }
}

@MainActor
final class PlanServiceStub: PlanServing {
    let response: PlanScreenData

    init(response: PlanScreenData) {
        self.response = response
    }

    func fetchPlan(days: Int) async -> PlanScreenData {
        let items = Array(response.items.prefix(days))
        return PlanScreenData(windowTitle: response.windowTitle, version: response.version, items: items)
    }
}

@MainActor
final class FeedbackServiceSpy: WorkoutServing {
    private(set) var didSubmit = false

    func fetchWorkouts() async -> [WorkoutListItemData] {
        []
    }

    func fetchWorkoutDetail(id: UUID) async -> WorkoutDetailData? {
        _ = id
        return nil
    }

    func submitFeedback(workoutID: UUID, draft: FeedbackDraft) async {
        _ = workoutID
        _ = draft
        didSubmit = true
    }
}

extension WorkoutImportPayload {
    static func fixture(userID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!) -> WorkoutImportPayload {
        WorkoutImportPayload(
            userID: userID,
            source: "healthkit",
            sourceWorkoutID: "hk-1",
            startedAt: Date(timeIntervalSince1970: 1_742_710_200),
            endedAt: Date(timeIntervalSince1970: 1_742_712_000),
            durationSec: 1_800,
            distanceM: 5_000,
            avgHeartRate: 148,
            maxHeartRate: 162,
            avgCadence: 168,
            isOutdoor: true,
            hasRoute: true,
            laps: [
                WorkoutLapPayload(
                    lapIndex: 1,
                    distanceM: 1_000,
                    durationSec: 360,
                    avgPaceSecPerKm: 360,
                    avgHeartRate: 146,
                    avgCadence: 168
                )
            ],
            distributions: [
                WorkoutDistributionPayload(
                    distributionType: "pace_distribution",
                    bucketKey: "easy",
                    durationSec: 1_800,
                    distanceM: 5_000,
                    percentage: 100
                )
            ],
            rawPayload: ["device": "Apple Watch"]
        )
    }
}

extension WorkoutImportResponse {
    static func fixture() -> WorkoutImportResponse {
        WorkoutImportResponse(
            workoutID: "workout-1",
            deduplicated: false,
            importJobID: "import-1",
            analysisJobID: "analysis-1"
        )
    }
}

extension HealthKitWorkoutRecord {
    static func fixture() -> HealthKitWorkoutRecord {
        HealthKitWorkoutRecord(
            sourceWorkoutID: "hk-1",
            startedAt: Date(timeIntervalSince1970: 1_742_710_200),
            endedAt: Date(timeIntervalSince1970: 1_742_712_000),
            durationSec: 1_800,
            distanceM: 5_000,
            avgHeartRate: 148,
            maxHeartRate: 162,
            avgCadence: 168,
            isOutdoor: true,
            hasRoute: true,
            laps: [
                WorkoutLapPayload(
                    lapIndex: 1,
                    distanceM: 1_000,
                    durationSec: 360,
                    avgPaceSecPerKm: 360,
                    avgHeartRate: 146,
                    avgCadence: 168
                )
            ],
            distributions: [
                WorkoutDistributionPayload(
                    distributionType: "pace_distribution",
                    bucketKey: "easy",
                    durationSec: 1_800,
                    distanceM: 5_000,
                    percentage: 100
                )
            ],
            deviceName: "Apple Watch"
        )
    }
}
