import Foundation
import OSLog

/// Central cleanup execution engine that processes user-confirmed cleanup operations.
/// Only operates on items that have passed SafetyValidator and received user confirmation.
public nonisolated final class CleanEngine: Sendable {
    private let deletionService: DeletionService

    public init(safetyValidator: SafetyValidator) {
        self.deletionService = DeletionService(safetyValidator: safetyValidator)
    }

    /// Executes cleanup operations for all selected items with live progress reporting.
    /// - Parameters:
    ///   - items: The user-confirmed cleanup items (only selected items are processed).
    ///   - progressHandler: Optional callback reporting live deletion progress and bytes freed.
    /// - Returns: An aggregate `CleanResult`.
    @concurrent
    public func clean(
        items: [CleanupItem],
        progressHandler: (@Sendable (CleanProgress) -> Void)? = nil
    ) async -> CleanResult {
        let startTime = Date()
        let selectedItems = items.filter(\.isSelected)
        let totalTargetBytes = selectedItems.reduce(0) { $0 + $1.size }

        Logger.cleaner.info("Starting cleanup: \(selectedItems.count) items (\(ByteFormatter.format(totalTargetBytes)))")

        var successCount = 0
        var failureCount = 0
        var totalReclaimed: Int64 = 0
        var failures: [CleanOperationResult] = []

        // Initial progress update
        progressHandler?(CleanProgress(
            currentItemName: selectedItems.first?.displayName ?? "Preparing cleanup…",
            currentItemPath: selectedItems.first?.url.path ?? "",
            currentCategory: selectedItems.first?.category,
            completedItemsCount: 0,
            totalItemsCount: selectedItems.count,
            bytesReclaimed: 0,
            totalBytes: totalTargetBytes
        ))

        var lastProgress = ContinuousClock.now
        for item in selectedItems {
            if Task.isCancelled {
                // Keep unprocessed items visible and selected for a later retry.
                for pending in selectedItems.dropFirst(successCount + failureCount) {
                    failures.append(CleanOperationResult(url: pending.url, success: false, error: "Cleanup cancelled"))
                }
                failureCount = failures.count
                break
            }

            let result = deletionService.safeDelete(item.url)

            if result.success {
                successCount += 1
                totalReclaimed += item.size
            } else {
                failureCount += 1
                failures.append(result)
            }

            // Report progress after item deleted
            if successCount + failureCount == selectedItems.count || ContinuousClock.now - lastProgress >= .milliseconds(100) {
                lastProgress = .now
                progressHandler?(CleanProgress(
                    currentItemName: item.displayName,
                    currentItemPath: item.url.path,
                    currentCategory: item.category,
                    completedItemsCount: successCount + failureCount,
                    totalItemsCount: selectedItems.count,
                    bytesReclaimed: totalReclaimed,
                    totalBytes: totalTargetBytes
                ))
            }
        }

        let duration = Date().timeIntervalSince(startTime)

        Logger.cleaner.info("Cleanup complete: \(successCount) succeeded, \(failureCount) failed, \(ByteFormatter.format(totalReclaimed)) reclaimed in \(String(format: "%.2f", duration))s")

        return CleanResult(
            totalItemsProcessed: successCount + failureCount,
            successCount: successCount,
            failureCount: failureCount,
            totalBytesReclaimed: totalReclaimed,
            failures: failures,
            duration: duration
        )
    }
}
