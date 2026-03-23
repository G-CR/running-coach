import Foundation

protocol SyncQueueStoring: Sendable {
    func enqueue(_ workout: WorkoutImportPayload) async
    func snapshot() async -> [WorkoutImportPayload]
    func replace(with items: [WorkoutImportPayload]) async
}

actor InMemorySyncQueueStore: SyncQueueStoring {
    private var pendingItems: [WorkoutImportPayload]

    init(pendingItems: [WorkoutImportPayload] = []) {
        self.pendingItems = pendingItems
    }

    func enqueue(_ workout: WorkoutImportPayload) async {
        pendingItems.append(workout)
    }

    func snapshot() async -> [WorkoutImportPayload] {
        pendingItems
    }

    func replace(with items: [WorkoutImportPayload]) async {
        pendingItems = items
    }
}
