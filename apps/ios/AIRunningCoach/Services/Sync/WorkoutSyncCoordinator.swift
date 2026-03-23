import Foundation

protocol WorkoutSyncCoordinating: Sendable {
    func sync(workout: WorkoutImportPayload) async throws
}

final class WorkoutSyncCoordinator: @unchecked Sendable {
    private let apiClientProvider: @Sendable () -> APIClientProtocol
    private let queueStore: SyncQueueStoring

    init(apiClient: APIClientProtocol, queueStore: SyncQueueStoring) {
        self.apiClientProvider = { apiClient }
        self.queueStore = queueStore
    }

    init(
        apiClientProvider: @escaping @Sendable () -> APIClientProtocol,
        queueStore: SyncQueueStoring
    ) {
        self.apiClientProvider = apiClientProvider
        self.queueStore = queueStore
    }

    func sync(workout: WorkoutImportPayload) async throws {
        do {
            _ = try await apiClientProvider().importWorkout(workout)
            await retryPending()
        } catch {
            await queueStore.enqueue(workout)
            throw error
        }
    }

    func retryPending() async {
        let pendingItems = await queueStore.snapshot()
        var remainingItems: [WorkoutImportPayload] = []

        for workout in pendingItems {
            do {
                _ = try await apiClientProvider().importWorkout(workout)
            } catch {
                remainingItems.append(workout)
            }
        }

        await queueStore.replace(with: remainingItems)
    }
}

extension WorkoutSyncCoordinator: WorkoutSyncCoordinating {}
