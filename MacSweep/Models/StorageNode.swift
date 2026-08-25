import Foundation

/// Represents a node in the hierarchical storage tree used by the Storage Analyzer.
/// Each node corresponds to a file or directory with computed size information.
public struct StorageNode: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let size: Int64
    public var children: [StorageNode]

    /// Formatted size string for UI display.
    public var formattedSize: String {
        ByteFormatter.format(size)
    }

    /// Number of direct children.
    public var childCount: Int {
        children.count
    }

    /// Percentage of parent size (set by parent during tree construction).
    public var percentageOfParent: Double = 0

    public init(
        id: UUID = UUID(),
        url: URL,
        name: String? = nil,
        isDirectory: Bool,
        size: Int64,
        children: [StorageNode] = []
    ) {
        self.id = id
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.isDirectory = isDirectory
        self.size = size
        self.children = children
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: StorageNode, rhs: StorageNode) -> Bool {
        lhs.id == rhs.id
    }
}
