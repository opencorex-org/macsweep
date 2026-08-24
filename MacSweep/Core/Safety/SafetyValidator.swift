import Foundation
import OSLog

/// Central safety validation engine that enforces all safety rules before cleanup.
/// Every candidate item must pass through this validator before being queued for deletion.
public final class SafetyValidator: Sendable {
    private let policy: SafetyPolicy
    private let homeDirectory: URL

    public init(policy: SafetyPolicy = .default) {
        self.policy = policy
        self.homeDirectory = FileManager.default.homeDirectoryForCurrentUser
    }

    /// Validates whether a URL is safe for cleanup operations.
    /// - Parameter url: The candidate file or directory URL.
    /// - Returns: A `ValidationResult` indicating pass/fail with a reason.
    public func validate(_ url: URL) -> ValidationResult {
        let path = url.path

        // Step 1: Check for path traversal components
        if PathValidator.containsTraversal(path) {
            Logger.safety.warning("Path traversal rejected: \(path, privacy: .private)")
            return .rejected(reason: "Path contains traversal components")
        }

        // Step 2: Check against protected system roots
        if ProtectedPaths.isSystemProtected(path) {
            Logger.safety.warning("Protected system path rejected: \(path, privacy: .private)")
            return .rejected(reason: "Protected system directory")
        }

        // Step 3: Check against protected user paths
        if ProtectedPaths.isUserProtected(path, homeDirectory: homeDirectory) {
            Logger.safety.warning("Protected user path rejected: \(path, privacy: .private)")
            return .rejected(reason: "Protected user configuration")
        }

        // Step 4: Check for sensitive file extensions
        if ProtectedPaths.hasSensitiveExtension(url) {
            Logger.safety.warning("Sensitive file extension rejected: \(path, privacy: .private)")
            return .rejected(reason: "Sensitive credential file type")
        }

        // Step 5: Resolve symlinks and verify boundaries
        if policy.verifySymlinks && PathValidator.isSymlink(url) {
            let resolved = url.resolvingSymlinksInPath()
            let resolvedPath = resolved.path

            if ProtectedPaths.isSystemProtected(resolvedPath) {
                Logger.safety.error("Symlink escape to system path: \(path, privacy: .private) → \(resolvedPath, privacy: .private)")
                return .rejected(reason: "Symlink points to protected system path")
            }
        }

        // Step 6: Check if file is locked
        if policy.skipLockedFiles && PermissionValidator.isLocked(url) {
            Logger.safety.info("Locked file skipped: \(path, privacy: .private)")
            return .skipped(reason: "File is locked by the system")
        }

        // Step 7: Verify deletion permissions
        if !PermissionValidator.isDeletable(url) {
            return .skipped(reason: "Insufficient permissions to delete")
        }

        return .approved
    }

    /// Batch validates an array of URLs and returns only approved items.
    public func filterApproved(_ urls: [URL]) -> [URL] {
        return urls.filter { validate($0) == .approved }
    }
}

/// Result of a safety validation check.
public enum ValidationResult: Equatable, Sendable {
    /// Item passed all safety checks and is approved for user review.
    case approved
    /// Item was explicitly rejected due to safety violation.
    case rejected(reason: String)
    /// Item was skipped due to permission or state issues (not a safety violation).
    case skipped(reason: String)

    public static func == (lhs: ValidationResult, rhs: ValidationResult) -> Bool {
        switch (lhs, rhs) {
        case (.approved, .approved): return true
        case (.rejected(let a), .rejected(let b)): return a == b
        case (.skipped(let a), .skipped(let b)): return a == b
        default: return false
        }
    }
}
