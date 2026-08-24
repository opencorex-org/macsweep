import Foundation
import OSLog

/// Coordinates cleanup lifecycle, managing active operations and cancellation.
public actor CleanCoordinator {
    private let cleanEngine: CleanEngine
    private var currentCleanTask: Task<CleanResult, Never>?

    public var isCleaning: Bool {
        currentCleanTask != nil && currentCleanTask?.isCancelled == false
    }

    public init(cleanEngine: CleanEngine) {
        self.cleanEngine = cleanEngine
    }

    /// Starts a cleanup operation for the given items.
    public func startCleanup(items: [CleanupItem]) async -> CleanResult {
        cancelCurrentCleanup()

        let task = Task {
            await cleanEngine.clean(items: items)
        }
        currentCleanTask = task
        let result = await task.value
        currentCleanTask = nil
        return result
    }

    /// Cancels any currently running cleanup operation.
    public func cancelCurrentCleanup() {
        currentCleanTask?.cancel()
        currentCleanTask = nil
        Logger.cleaner.info("Cleanup cancelled")
    }
}
