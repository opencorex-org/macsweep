import Foundation

/// Raw item discovered during scanning, before safety validation.
/// This is the Scanner's output type, distinct from the validated CleanupItem.
public struct ScanItem: Sendable {
    public let url: URL
    public let size: Int64
    public let category: CleanupCategory
    public let isDirectory: Bool
    public let modificationDate: Date

    public init(url: URL, size: Int64, category: CleanupCategory, isDirectory: Bool, modificationDate: Date) {
        self.url = url
        self.size = size
        self.category = category
        self.isDirectory = isDirectory
        self.modificationDate = modificationDate
    }

    /// Converts this raw scan item to a validated CleanupItem.
    public func toCleanupItem(risk: CleanupRisk? = nil) -> CleanupItem {
        CleanupItem(
            url: url,
            size: size,
            category: category,
            risk: risk,
            isDirectory: isDirectory,
            modificationDate: modificationDate
        )
    }
}
