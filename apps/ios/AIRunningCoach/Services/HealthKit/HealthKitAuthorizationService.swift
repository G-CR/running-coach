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
    private static let authorizationFlagKey = "healthkit_read_authorized"

    private let healthStore: HKHealthStore
    private let userDefaults: UserDefaults

    init(healthStore: HKHealthStore = HKHealthStore(), userDefaults: UserDefaults = .standard) {
        self.healthStore = healthStore
        self.userDefaults = userDefaults
    }

    func currentStatus() -> HealthKitAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }
        return userDefaults.bool(forKey: Self.authorizationFlagKey) ? .authorized : .pending
    }

    func requestAuthorization() async throws -> HealthKitAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HealthKitAuthorizationState, Error>) in
            healthStore.requestAuthorization(toShare: [], read: readTypes()) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    self.userDefaults.set(true, forKey: Self.authorizationFlagKey)
                    continuation.resume(returning: .authorized)
                } else {
                    self.userDefaults.removeObject(forKey: Self.authorizationFlagKey)
                    continuation.resume(returning: .pending)
                }
            }
        }
    }

    private func readTypes() -> Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        return types
    }
}
