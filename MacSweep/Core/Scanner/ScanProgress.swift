import Foundation

/// Real-time progress reporting state for active scan operations.
public struct ScanProgress: Sendable {
    public let currentCategory: CleanupCategory?
    public let currentPath: String
    public let scannedBytes: Int64
    public let scannedItemsCount: Int
    public let completedCategoriesCount: Int
    public let totalCategoriesCount: Int
    public let isComplete: Bool

    /// Overall category-level progress for the Smart Scan progress bar.
    public var fractionCompleted: Double {
        guard totalCategoriesCount > 0 else { return isComplete ? 1 : 0 }
        return isComplete ? 1 : min(Double(completedCategoriesCount) / Double(totalCategoriesCount), 1)
    }

    /// Formatted scanned bytes for display.
    public var formattedScannedSize: String {
        ByteFormatter.format(scannedBytes)
    }

    public init(
        currentCategory: CleanupCategory? = nil,
        currentPath: String = "",
        scannedBytes: Int64 = 0,
        scannedItemsCount: Int = 0,
        completedCategoriesCount: Int = 0,
        totalCategoriesCount: Int = 0,
        isComplete: Bool = false
    ) {
        self.currentCategory = currentCategory
        self.currentPath = currentPath
        self.scannedBytes = scannedBytes
        self.scannedItemsCount = scannedItemsCount
        self.completedCategoriesCount = completedCategoriesCount
        self.totalCategoriesCount = totalCategoriesCount
        self.isComplete = isComplete
    }

    /// Creates a completed progress state.
    public static func completed(totalBytes: Int64, totalItems: Int, totalCategories: Int) -> ScanProgress {
        ScanProgress(
            scannedBytes: totalBytes,
            scannedItemsCount: totalItems,
            completedCategoriesCount: totalCategories,
            totalCategoriesCount: totalCategories,
            isComplete: true
        )
    }
}
