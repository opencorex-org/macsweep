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
    case groupContainers
    case savedState
    case httpStorage
    case webKit
    case cookies
    case applicationScripts
    case launchAgent
    case launchDaemon
    case helperTool
    case crashReports
    case sdkSupport

    public var displayName: String {
        switch self {
        case .preferences: "Preferences"
        case .applicationSupport: "Application Support"
        case .caches: "Caches"
        case .logs: "Logs"
        case .containers: "App Container"
        case .groupContainers: "Group Container"
        case .savedState: "Saved State"
        case .httpStorage: "HTTP Storage"
        case .webKit: "WebKit Data"
        case .cookies: "Cookies"
        case .applicationScripts: "Application Scripts"
        case .launchAgent: "Launch Agent"
        case .launchDaemon: "Launch Daemon"
        case .helperTool: "Helper Tool"
        case .crashReports: "Crash Reports"
        case .sdkSupport: "App-owned SDK / Support Data"
        }
    }

    public var iconName: String {
        switch self {
        case .preferences: "slider.horizontal.3"
        case .applicationSupport, .sdkSupport: "folder.fill"
        case .caches: "internaldrive.fill"
        case .logs, .crashReports: "doc.text.fill"
        case .containers, .groupContainers: "shippingbox.fill"
        case .savedState: "clock.arrow.circlepath"
        case .httpStorage, .webKit, .cookies: "globe"
        case .applicationScripts: "applescript.fill"
        case .launchAgent, .launchDaemon: "bolt.fill"
        case .helperTool: "wrench.and.screwdriver.fill"
        }
    }
}
