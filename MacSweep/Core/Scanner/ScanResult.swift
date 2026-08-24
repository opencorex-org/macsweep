import Foundation

/// Aggregate container for scan results from a complete Smart Scan operation.
public struct ScanResult: Sendable {
    public var items: [CleanupItem]
    public let duration: TimeInterval
    public let scannedCategories: [CleanupCategory]

    /// Total bytes across all discovered items.
    public var totalBytes: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    /// Total bytes for selected items only.
    public var selectedBytes: Int64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    /// Number of selected items.
    public var selectedCount: Int {
        items.filter(\.isSelected).count
    }

    /// Items grouped by category.
    public var groupedByCategory: [CleanupCategory: [CleanupItem]] {
        Dictionary(grouping: items, by: \.category)
    }

    /// Formatted total size string.
    public var formattedTotalSize: String {
        ByteFormatter.format(totalBytes)
    }

    /// Formatted selected size string.
    public var formattedSelectedSize: String {
        ByteFormatter.format(selectedBytes)
    }

    public init(items: [CleanupItem] = [], duration: TimeInterval = 0, scannedCategories: [CleanupCategory] = []) {
        self.items = items
        self.duration = duration
        self.scannedCategories = scannedCategories
    }
}
