import Foundation

/// Real-time progress reporting state for active scan operations.
public struct ScanProgress: Sendable {
    public let currentCategory: CleanupCategory?
    public let currentPath: String
    public let scannedBytes: Int64
    public let scannedItemsCount: Int
    public let isComplete: Bool

    /// Formatted scanned bytes for display.
    public var formattedScannedSize: String {
        ByteFormatter.format(scannedBytes)
    }

    public init(
        currentCategory: CleanupCategory? = nil,
        currentPath: String = "",
        scannedBytes: Int64 = 0,
        scannedItemsCount: Int = 0,
        isComplete: Bool = false
    ) {
        self.currentCategory = currentCategory
        self.currentPath = currentPath
        self.scannedBytes = scannedBytes
        self.scannedItemsCount = scannedItemsCount
        self.isComplete = isComplete
    }

    /// Creates a completed progress state.
    public static func completed(totalBytes: Int64, totalItems: Int) -> ScanProgress {
        ScanProgress(
            scannedBytes: totalBytes,
            scannedItemsCount: totalItems,
            isComplete: true
        )
    }
}
