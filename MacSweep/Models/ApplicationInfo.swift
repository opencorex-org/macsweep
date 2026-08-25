import Foundation

/// Represents an installed macOS application and its associated leftover files.
public struct ApplicationInfo: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let bundleIdentifier: String
    public let name: String
    public let bundleURL: URL
    public let version: String
    public let iconPath: String?
    public let bundleSize: Int64
    public var leftovers: [LeftoverFile]
    public var isSelected: Bool

    /// Total leftover size across all associated files.
    public var leftoverSize: Int64 {
        leftovers.reduce(0) { $0 + $1.size }
    }

    /// Total size (bundle + leftovers).
    public var totalSize: Int64 {
        bundleSize + leftoverSize
    }

    /// Formatted total size for display.
    public var formattedTotalSize: String {
        ByteFormatter.format(totalSize)
    }

    public init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        name: String,
        bundleURL: URL,
        version: String = "",
        iconPath: String? = nil,
        bundleSize: Int64 = 0,
        leftovers: [LeftoverFile] = [],
        isSelected: Bool = false
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.bundleURL = bundleURL
        self.version = version
        self.iconPath = iconPath
        self.bundleSize = bundleSize
        self.leftovers = leftovers
        self.isSelected = isSelected
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ApplicationInfo, rhs: ApplicationInfo) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a leftover file associated with an uninstalled or installed application.
public struct LeftoverFile: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let size: Int64
    public let type: LeftoverType

    public init(
        id: UUID = UUID(),
        url: URL,
        name: String? = nil,
        size: Int64,
        type: LeftoverType
    ) {
        self.id = id
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.size = size
        self.type = type
    }
}

/// Classification of leftover file types.
public enum LeftoverType: String, Codable, Sendable {
    case preferences
    case applicationSupport
    case caches
    case logs
    case containers
    case savedState
    case httpStorage
}
