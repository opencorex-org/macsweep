import Foundation
import OSLog

/// Validates read/write permissions on file paths before scan or cleanup operations.
public struct PermissionValidator: Sendable {
    private static let fileManager = FileManager.default

    /// Checks if a path is readable.
    public static func isReadable(_ url: URL) -> Bool {
        return fileManager.isReadableFile(atPath: url.path)
    }

    /// Checks if a path is writable (required for deletion).
    public static func isWritable(_ url: URL) -> Bool {
        return fileManager.isWritableFile(atPath: url.path)
    }

    /// Checks if a path is deletable.
    public static func isDeletable(_ url: URL) -> Bool {
        return fileManager.isDeletableFile(atPath: url.path)
    }

    /// Checks if a file is locked by the system.
    public static func isLocked(_ url: URL) -> Bool {
        guard let resourceValues = try? url.resourceValues(forKeys: [.isUserImmutableKey, .isSystemImmutableKey]) else {
            return false
        }
        return (resourceValues.isUserImmutable ?? false) || (resourceValues.isSystemImmutable ?? false)
    }

    /// Comprehensive permission check for cleanup operations.
    /// Returns a tuple indicating (canRead, canDelete, isLocked).
    public static func checkPermissions(_ url: URL) -> (canRead: Bool, canDelete: Bool, isLocked: Bool) {
        return (
            canRead: isReadable(url),
            canDelete: isDeletable(url),
            isLocked: isLocked(url)
        )
    }
}
