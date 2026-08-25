import Foundation

/// Represents a group of duplicate files sharing identical content.
public struct DuplicateGroup: Identifiable, Sendable {
    public let id: UUID
    public let fileHash: String
    public let fileSize: Int64
    public var files: [DuplicateFile]

    /// Total wasted space (all duplicates minus one original).
    public var wastedSpace: Int64 {
        max(0, fileSize * Int64(files.count - 1))
    }

    /// Formatted wasted space for display.
    public var formattedWastedSpace: String {
        ByteFormatter.format(wastedSpace)
    }

    /// Number of duplicate copies.
    public var duplicateCount: Int {
        files.count
    }

    public init(
        id: UUID = UUID(),
        fileHash: String,
        fileSize: Int64,
        files: [DuplicateFile]
    ) {
        self.id = id
        self.fileHash = fileHash
        self.fileSize = fileSize
        self.files = files
    }
}

/// A single file within a duplicate group.
public struct DuplicateFile: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let modificationDate: Date
    public var isSelected: Bool
    public var isOriginal: Bool

    public init(
        id: UUID = UUID(),
        url: URL,
        name: String? = nil,
        modificationDate: Date,
        isSelected: Bool = false,
        isOriginal: Bool = false
    ) {
        self.id = id
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.modificationDate = modificationDate
        self.isSelected = isSelected
        self.isOriginal = isOriginal
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: DuplicateFile, rhs: DuplicateFile) -> Bool {
        lhs.id == rhs.id
    }
}
