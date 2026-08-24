import Foundation
import OSLog

/// Manages controlled file access for scan and cleanup operations.
public final class FileAccessManager: Sendable {
    public static let shared = FileAccessManager()

    private let fileManager = FileManager.default

    /// Returns the user's home directory.
    public var homeDirectory: URL {
        fileManager.homeDirectoryForCurrentUser
    }

    /// Returns the user's Library directory.
    public var libraryDirectory: URL {
        homeDirectory.appendingPathComponent("Library")
    }

    /// Returns the user's Caches directory.
    public var cachesDirectory: URL {
        libraryDirectory.appendingPathComponent("Caches")
    }

    /// Returns the user's Logs directory.
    public var logsDirectory: URL {
        libraryDirectory.appendingPathComponent("Logs")
    }

    /// Returns commonly scannable root directories.
    public var scannableRoots: [URL] {
        [
            homeDirectory,
            homeDirectory.appendingPathComponent("Downloads"),
            homeDirectory.appendingPathComponent("Documents"),
            homeDirectory.appendingPathComponent("Desktop"),
            homeDirectory.appendingPathComponent("Movies"),
            homeDirectory.appendingPathComponent("Music")
        ]
    }
}
