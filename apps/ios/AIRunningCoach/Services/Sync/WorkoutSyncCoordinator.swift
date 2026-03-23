import Foundation

final class WorkoutSyncCoordinator: @unchecked Sendable {
    private let apiClient: APIClientProtocol
    private let queueStore: SyncQueueStoring

    init(apiClient: APIClientProtocol, queueStore: SyncQueueStoring) {
        self.apiClient = apiClient
        self.queueStore = queueStore
    }

    func sync(workout: WorkoutImportPayload) async throws {
        do {
            _ = try await apiClient.importWorkout(workout)
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
                _ = try await apiClient.importWorkout(workout)
            } catch {
                remainingItems.append(workout)
            }
        }

        await queueStore.replace(with: remainingItems)
    }
}
