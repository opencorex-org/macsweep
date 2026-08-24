import Foundation
import OSLog

/// Central cleanup execution engine that processes user-confirmed cleanup operations.
/// Only operates on items that have passed SafetyValidator and received user confirmation.
public final class CleanEngine: Sendable {
    private let deletionService: DeletionService

    public init(safetyValidator: SafetyValidator) {
        self.deletionService = DeletionService(safetyValidator: safetyValidator)
    }

    /// Executes cleanup operations for all selected items.
    /// - Parameter items: The user-confirmed cleanup items (only selected items are processed).
    /// - Returns: An aggregate `CleanResult`.
    public func clean(items: [CleanupItem]) async -> CleanResult {
        let startTime = Date()
        let selectedItems = items.filter(\.isSelected)

        Logger.cleaner.info("Starting cleanup: \(selectedItems.count) items")

        var successCount = 0
        var failureCount = 0
        var totalReclaimed: Int64 = 0
        var failures: [CleanOperationResult] = []

        for item in selectedItems {
            if Task.isCancelled { break }

            let result = deletionService.safeDelete(item.url)

            if result.success {
                successCount += 1
                totalReclaimed += item.size
            } else {
                failureCount += 1
                failures.append(result)
            }
        }

        let duration = Date().timeIntervalSince(startTime)

        Logger.cleaner.info("Cleanup complete: \(successCount) succeeded, \(failureCount) failed, \(ByteFormatter.format(totalReclaimed)) reclaimed")

        return CleanResult(
            totalItemsProcessed: selectedItems.count,
            successCount: successCount,
            failureCount: failureCount,
            totalBytesReclaimed: totalReclaimed,
            failures: failures,
            duration: duration
        )
    }
}
