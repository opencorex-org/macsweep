import Foundation
import OSLog

/// Validates and canonicalizes file paths to prevent symlink attacks and path traversal.
public struct PathValidator: Sendable {
    /// Resolves the canonical path by following symlinks and verifying the result
    /// stays within acceptable boundaries.
    /// - Parameters:
    ///   - url: The URL to validate.
    ///   - allowedRoots: Set of allowed root paths the resolved path must reside under.
    /// - Returns: The resolved canonical URL.
    /// - Throws: `MacSweepError.symlinkEscape` if the resolved path escapes boundaries.
    public static func resolveAndValidate(_ url: URL, allowedRoots: [URL]) throws -> URL {
        let resolved = url.resolvingSymlinksInPath()
        let resolvedPath = resolved.path

        // Check the resolved path is within an allowed root
        let isAllowed = allowedRoots.contains { root in
            resolvedPath.hasPrefix(root.path)
        }

        guard isAllowed else {
            Logger.safety.error("Symlink escape detected: \(url.path, privacy: .private) → \(resolvedPath, privacy: .private)")
            throw MacSweepError.symlinkEscape(path: url.path, resolvedPath: resolvedPath)
        }

        return resolved
    }

    /// Checks whether a URL points to a symbolic link.
    public static func isSymlink(_ url: URL) -> Bool {
        let resourceValues = try? url.resourceValues(forKeys: [.isSymbolicLinkKey])
        return resourceValues?.isSymbolicLink ?? false
    }

    /// Validates that a path does not contain path traversal components like ".."
    public static func containsTraversal(_ path: String) -> Bool {
        let components = (path as NSString).pathComponents
        return components.contains("..")
    }
}
