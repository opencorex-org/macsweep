import Foundation

/// Represents a single file or directory identified as cleanable during scanning.
/// This is the fundamental unit of work flowing through Scanner → Safety → Cleaner pipeline.
public struct CleanupItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let size: Int64
    public let category: CleanupCategory
    public let risk: CleanupRisk
    public let isDirectory: Bool
    public let modificationDate: Date
    public var isSelected: Bool

    /// Formatted size string for UI display.
    public var formattedSize: String {
        ByteFormatter.format(size)
    }

    /// Relative date string for UI display.
    public var relativeDate: String {
        AppDateFormatter.relative(modificationDate)
    }

    public init(
        id: UUID = UUID(),
        url: URL,
        name: String? = nil,
        size: Int64,
        category: CleanupCategory,
        risk: CleanupRisk? = nil,
        isDirectory: Bool,
        modificationDate: Date,
        isSelected: Bool = true
    ) {
        self.id = id
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.size = size
        self.category = category
        self.risk = risk ?? category.defaultRisk
        self.isDirectory = isDirectory
        self.modificationDate = modificationDate
        self.isSelected = isSelected
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: CleanupItem, rhs: CleanupItem) -> Bool {
        lhs.id == rhs.id
    }
}
