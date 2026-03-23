import Foundation

struct HealthKitWorkoutRecord: Equatable, Sendable {
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
    let deviceName: String
}

protocol HealthKitWorkoutSource: Sendable {
    func readWorkouts(since anchor: Date?) async throws -> [HealthKitWorkoutRecord]
}

final class HealthKitWorkoutReader: @unchecked Sendable {
    private let source: HealthKitWorkoutSource
    private(set) var lastAnchor: Date?

    init(source: HealthKitWorkoutSource, lastAnchor: Date? = nil) {
        self.source = source
        self.lastAnchor = lastAnchor
    }

    func readWorkouts(userID: UUID) async throws -> [WorkoutImportPayload] {
        let records = try await source.readWorkouts(since: lastAnchor)
        if let latestEndedAt = records.map(\.endedAt).max() {
            lastAnchor = latestEndedAt
        }

        return records.map { record in
            WorkoutImportPayload(
                userID: userID,
                source: "healthkit",
                sourceWorkoutID: record.sourceWorkoutID,
                startedAt: record.startedAt,
                endedAt: record.endedAt,
                durationSec: record.durationSec,
                distanceM: record.distanceM,
                avgHeartRate: record.avgHeartRate,
                maxHeartRate: record.maxHeartRate,
                avgCadence: record.avgCadence,
                isOutdoor: record.isOutdoor,
                hasRoute: record.hasRoute,
                laps: record.laps,
                distributions: record.distributions,
                rawPayload: ["device": record.deviceName]
            )
        }
    }
}
