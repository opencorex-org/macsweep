import Foundation
import OSLog

/// Handles safe file relocation to the macOS Trash using native FileManager APIs.
/// This is the primary deletion mechanism — never uses shell commands.
public struct TrashService: Sendable {
    /// Moves a file or directory to the macOS Trash.
    /// - Parameter url: The file or directory URL to trash.
    /// - Returns: The resulting URL in the Trash directory.
    /// - Throws: `MacSweepError.trashFailed` if the operation fails.
    public static func moveToTrash(_ url: URL) throws -> URL {
        var resultURL: NSURL?
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: &resultURL)
            Logger.cleaner.info("Moved to Trash: \(url.lastPathComponent, privacy: .public)")
            return (resultURL as URL?) ?? url
        } catch {
            Logger.cleaner.error("Trash failed for \(url.path, privacy: .private): \(error.localizedDescription)")
            throw MacSweepError.trashFailed(path: url.path, reason: error.localizedDescription)
        }
    }
}
