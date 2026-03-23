import Foundation
import HealthKit

enum HealthKitAuthorizationState: Equatable {
    case unknown
    case unavailable
    case pending
    case authorized

    var description: String {
        switch self {
        case .unknown:
            return "尚未检查授权状态"
        case .unavailable:
            return "当前设备不支持 HealthKit"
        case .pending:
            return "HealthKit 尚未授权"
        case .authorized:
            return "HealthKit 已授权，可同步跑步数据"
        }
    }
}

protocol HealthKitAuthorizationProviding: Sendable {
    func currentStatus() -> HealthKitAuthorizationState
    func requestAuthorization() async throws -> HealthKitAuthorizationState
}

final class HealthKitAuthorizationService: HealthKitAuthorizationProviding, @unchecked Sendable {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func currentStatus() -> HealthKitAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        switch status {
        case .sharingAuthorized:
            return .authorized
        case .notDetermined, .sharingDenied:
            return .pending
        @unknown default:
            return .unknown
        }
    }

    func requestAuthorization() async throws -> HealthKitAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }

        let workoutType = HKObjectType.workoutType()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HealthKitAuthorizationState, Error>) in
            healthStore.requestAuthorization(toShare: [], read: [workoutType]) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: .authorized)
                } else {
                    continuation.resume(returning: .pending)
                }
            }
        }
    }
}
