import Foundation

/// Represents a large file discovered by the Large File Finder.
public struct LargeFile: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let size: Int64
    public let modificationDate: Date
    public let fileType: String
    public var isSelected: Bool

    /// Formatted size for display.
    public var formattedSize: String {
        ByteFormatter.format(size)
    }

    /// Relative date for display.
    public var relativeDate: String {
        AppDateFormatter.relative(modificationDate)
    }

    /// The containing directory path for display.
    public var directoryPath: String {
        url.deletingLastPathComponent().path
    }

    public init(
        id: UUID = UUID(),
        url: URL,
        name: String? = nil,
        size: Int64,
        modificationDate: Date,
        fileType: String = "Unknown",
        isSelected: Bool = false
    ) {
        self.id = id
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.size = size
        self.modificationDate = modificationDate
        self.fileType = fileType
        self.isSelected = isSelected
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: LargeFile, rhs: LargeFile) -> Bool {
        lhs.id == rhs.id
    }
}
