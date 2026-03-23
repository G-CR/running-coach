import Foundation
import HealthKit

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

protocol WorkoutImportReading: Sendable {
    func readWorkouts(userID: UUID) async throws -> [WorkoutImportPayload]
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

extension HealthKitWorkoutReader: WorkoutImportReading {}

final class LiveHealthKitWorkoutSource: HealthKitWorkoutSource, @unchecked Sendable {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func readWorkouts(since anchor: Date?) async throws -> [HealthKitWorkoutRecord] {
        guard HKHealthStore.isHealthDataAvailable() else {
            return []
        }

        let workouts = try await fetchRunningWorkouts(since: anchor)
        var records: [HealthKitWorkoutRecord] = []

        for workout in workouts {
            let distanceM = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
            guard distanceM > 0 else {
                continue
            }

            async let heartRateSummary = fetchQuantitySummary(
                identifier: .heartRate,
                for: workout,
                unit: HKUnit.count().unitDivided(by: .minute())
            )
            async let stepCount = fetchTotalQuantity(
                identifier: .stepCount,
                for: workout,
                unit: .count()
            )

            let heartRate = try await heartRateSummary
            let totalStepCount = try await stepCount
            let cadence = workout.duration > 0 ? (totalStepCount.map { $0 / (workout.duration / 60.0) }) : nil
            let isIndoor = (workout.metadata?[HKMetadataKeyIndoorWorkout] as? NSNumber)?.boolValue ?? false

            records.append(
                HealthKitWorkoutRecord(
                    sourceWorkoutID: workout.uuid.uuidString,
                    startedAt: workout.startDate,
                    endedAt: workout.endDate,
                    durationSec: Int(workout.duration.rounded()),
                    distanceM: distanceM,
                    avgHeartRate: heartRate.average,
                    maxHeartRate: heartRate.maximum,
                    avgCadence: cadence,
                    isOutdoor: !isIndoor,
                    hasRoute: false,
                    laps: [],
                    distributions: [],
                    deviceName: workout.sourceRevision.source.name
                )
            )
        }

        return records.sorted { $0.endedAt < $1.endedAt }
    }

    private func fetchRunningWorkouts(since anchor: Date?) async throws -> [HKWorkout] {
        var predicates: [NSPredicate] = [HKQuery.predicateForWorkouts(with: .running)]
        if let anchor {
            predicates.append(HKQuery.predicateForSamples(withStart: anchor, end: nil, options: .strictStartDate))
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let sampleType = HKObjectType.workoutType()
        let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchQuantitySummary(
        identifier: HKQuantityTypeIdentifier,
        for workout: HKWorkout,
        unit: HKUnit
    ) async throws -> (average: Double?, maximum: Double?) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return (nil, nil)
        }

        let samples = try await fetchQuantitySamples(type: quantityType, for: workout)
        let values = samples.map { $0.quantity.doubleValue(for: unit) }
        guard !values.isEmpty else {
            return (nil, nil)
        }

        let average = values.reduce(0, +) / Double(values.count)
        return (average, values.max())
    }

    private func fetchTotalQuantity(
        identifier: HKQuantityTypeIdentifier,
        for workout: HKWorkout,
        unit: HKUnit
    ) async throws -> Double? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let samples = try await fetchQuantitySamples(type: quantityType, for: workout)
        let values = samples.map { $0.quantity.doubleValue(for: unit) }
        guard !values.isEmpty else {
            return nil
        }
        return values.reduce(0, +)
    }

    private func fetchQuantitySamples(type: HKQuantityType, for workout: HKWorkout) async throws -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForObjects(from: workout)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
                }
            }
            healthStore.execute(query)
        }
    }
}
