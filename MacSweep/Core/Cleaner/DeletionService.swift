import Foundation
import OSLog

/// Provides safe, validated file deletion operations.
/// All deletions pass through SafetyValidator before execution.
public struct DeletionService: Sendable {
    private let safetyValidator: SafetyValidator

    public init(safetyValidator: SafetyValidator) {
        self.safetyValidator = safetyValidator
    }

    /// Safely deletes a file or directory by moving it to Trash.
    /// - Parameter url: The file URL to remove.
    /// - Returns: A `CleanOperationResult` indicating success or failure.
    public func safeDelete(_ url: URL) -> CleanOperationResult {
        // Final safety check before deletion
        let validation = safetyValidator.validate(url)
        guard validation == .approved else {
            return CleanOperationResult(
                url: url,
                success: false,
                error: "Safety validation failed"
            )
        }

        // Verify file still exists (may have been removed during review)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return CleanOperationResult(
                url: url,
                success: false,
                error: "File no longer exists"
            )
        }

        do {
            _ = try TrashService.moveToTrash(url)
            return CleanOperationResult(url: url, success: true)
        } catch {
            return CleanOperationResult(url: url, success: false, error: error.localizedDescription)
        }
    }
}

/// Result of a single cleanup operation.
public struct CleanOperationResult: Sendable {
    public let url: URL
    public let success: Bool
    public let error: String?

    public init(url: URL, success: Bool, error: String? = nil) {
        self.url = url
        self.success = success
        self.error = error
    }
}
