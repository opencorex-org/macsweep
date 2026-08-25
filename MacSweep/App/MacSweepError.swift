import Foundation

/// Unified, strongly-typed error hierarchy for all MacSweep operations.
public enum MacSweepError: LocalizedError, Sendable {
    case permissionDenied(path: String)
    case fileNotFound(path: String)
    case protectedPathViolation(path: String)
    case operationCancelled
    case trashFailed(path: String, reason: String)
    case deletionFailed(path: String, reason: String)
    case scanFailed(category: String, reason: String)
    case diskSpaceUnavailable
    case symlinkEscape(path: String, resolvedPath: String)
    case invalidPath(path: String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let path):
            return "Permission denied while accessing: \(path)"
        case .fileNotFound(let path):
            return "File or folder no longer exists at: \(path)"
        case .protectedPathViolation(let path):
            return "Operation blocked — protected system location: \(path)"
        case .operationCancelled:
            return "Operation was cancelled."
        case .trashFailed(let path, let reason):
            return "Failed to move to Trash: \(path) — \(reason)"
        case .deletionFailed(let path, let reason):
            return "Failed to delete: \(path) — \(reason)"
        case .scanFailed(let category, let reason):
            return "Scan failed for \(category): \(reason)"
        case .diskSpaceUnavailable:
            return "Unable to retrieve disk space information."
        case .symlinkEscape(let path, let resolvedPath):
            return "Symlink escape detected: \(path) → \(resolvedPath)"
        case .invalidPath(let path):
            return "Invalid or malformed path: \(path)"
        }
    }
}
