import Foundation

struct WorkoutImportPayload: Codable, Equatable, Sendable {
    let userID: UUID
    let source: String
    let sourceWorkoutID: String
    let startedAt: Date
    let endedAt: Date
    let durationSec: Int
    let distanceM: Double
    let avgHeartRate: Double?
    let maxHeartRate: Double?
    let avgCadence: Double?
    let isOutdoor: Bool
    let hasRoute: Bool
    let laps: [WorkoutLapPayload]
    let distributions: [WorkoutDistributionPayload]
    let rawPayload: [String: String]?
}

struct WorkoutLapPayload: Codable, Equatable, Sendable {
    let lapIndex: Int
    let distanceM: Double
    let durationSec: Int
    let avgPaceSecPerKm: Double?
    let avgHeartRate: Double?
    let avgCadence: Double?
}

struct WorkoutDistributionPayload: Codable, Equatable, Sendable {
    let distributionType: String
    let bucketKey: String
    let durationSec: Int?
    let distanceM: Double?
    let percentage: Double?
}

struct WorkoutImportResponse: Decodable, Equatable, Sendable {
    let workoutID: String
    let deduplicated: Bool
    let importJobID: String?
    let analysisJobID: String?

    enum CodingKeys: String, CodingKey {
        case workoutID = "workout_id"
        case deduplicated
        case importJobID = "import_job_id"
        case analysisJobID = "analysis_job_id"
    }
}
