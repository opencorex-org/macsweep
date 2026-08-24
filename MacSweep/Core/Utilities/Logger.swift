import OSLog

/// Centralized logging facility for MacSweep using Apple's unified logging system.
/// All log categories are organized by subsystem module to enable targeted diagnostics.
public extension Logger {
    private static let subsystem = "org.opencorex.macsweep"

    /// General application lifecycle events
    static let app = Logger(subsystem: subsystem, category: "App")

    /// File scanning operations and discovery events
    static let scanner = Logger(subsystem: subsystem, category: "Scanner")

    /// File deletion and trash relocation operations
    static let cleaner = Logger(subsystem: subsystem, category: "Cleaner")

    /// Safety validation, protected path checks, and risk assessment
    static let safety = Logger(subsystem: subsystem, category: "Safety")

    /// Permission checks, FDA status, and access scope management
    static let permissions = Logger(subsystem: subsystem, category: "Permissions")

    /// Disk space metrics, storage analysis, and size calculations
    static let storage = Logger(subsystem: subsystem, category: "Storage")

    /// File system enumeration and metadata operations
    static let fileSystem = Logger(subsystem: subsystem, category: "FileSystem")
}
