import Foundation

/// Defines the safety policy rules applied to candidate cleanup items.
public struct SafetyPolicy: Sendable {
    /// Minimum file age in days before items are eligible for safe cleanup.
    public let minimumAgeDays: Int

    /// Whether to skip items currently in use (locked files).
    public let skipLockedFiles: Bool

    /// Whether to resolve and verify symlinks before operations.
    public let verifySymlinks: Bool

    /// Default production safety policy.
    public static let `default` = SafetyPolicy(
        minimumAgeDays: 0,
        skipLockedFiles: true,
        verifySymlinks: true
    )

    /// Strict policy for high-risk operations.
    public static let strict = SafetyPolicy(
        minimumAgeDays: 7,
        skipLockedFiles: true,
        verifySymlinks: true
    )

    public init(minimumAgeDays: Int, skipLockedFiles: Bool, verifySymlinks: Bool) {
        self.minimumAgeDays = minimumAgeDays
        self.skipLockedFiles = skipLockedFiles
        self.verifySymlinks = verifySymlinks
    }
}
