import OSLog

/// Centralized logging facility for MacSweep using Apple's unified logging system.
/// All log categories are organized by subsystem module to enable targeted diagnostics.
public extension Logger {
    nonisolated private static let subsystem = "org.opencorex.macsweep"

    /// General application lifecycle events
    nonisolated static let app = Logger(subsystem: subsystem, category: "App")

    /// File scanning operations and discovery events
    nonisolated static let scanner = Logger(subsystem: subsystem, category: "Scanner")

    /// File deletion and trash relocation operations
    nonisolated static let cleaner = Logger(subsystem: subsystem, category: "Cleaner")

    /// Safety validation, protected path checks, and risk assessment
    nonisolated static let safety = Logger(subsystem: subsystem, category: "Safety")

    /// Permission checks, FDA status, and access scope management
    nonisolated static let permissions = Logger(subsystem: subsystem, category: "Permissions")

    /// Disk space metrics, storage analysis, and size calculations
    nonisolated static let storage = Logger(subsystem: subsystem, category: "Storage")

    /// File system enumeration and metadata operations
    nonisolated static let fileSystem = Logger(subsystem: subsystem, category: "FileSystem")

    /// App folder move and symlink operations
    nonisolated static let mover = Logger(subsystem: subsystem, category: "AppMover")

    /// External volume discovery and management
    nonisolated static let volumes = Logger(subsystem: subsystem, category: "Volumes")
}
