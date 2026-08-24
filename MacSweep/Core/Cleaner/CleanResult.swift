import Foundation

/// Aggregate result of a cleanup operation across multiple items.
public struct CleanResult: Sendable {
    public let totalItemsProcessed: Int
    public let successCount: Int
    public let failureCount: Int
    public let totalBytesReclaimed: Int64
    public let failures: [CleanOperationResult]
    public let duration: TimeInterval

    /// Formatted reclaimed space string.
    public var formattedReclaimed: String {
        ByteFormatter.format(totalBytesReclaimed)
    }

    /// Whether all operations succeeded.
    public var isFullSuccess: Bool {
        failureCount == 0
    }

    public init(
        totalItemsProcessed: Int,
        successCount: Int,
        failureCount: Int,
        totalBytesReclaimed: Int64,
        failures: [CleanOperationResult] = [],
        duration: TimeInterval = 0
    ) {
        self.totalItemsProcessed = totalItemsProcessed
        self.successCount = successCount
        self.failureCount = failureCount
        self.totalBytesReclaimed = totalBytesReclaimed
        self.failures = failures
        self.duration = duration
    }
}
