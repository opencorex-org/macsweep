import Foundation
import AppKit
import OSLog

/// High-level file system operations wrapper used across MacSweep.
public final class FileSystemService: Sendable {
    private let fileManager = FileManager.default

    public init() {}

    /// Checks if a directory exists at the given path.
    public func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    /// Checks if a file exists at the given path.
    public func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }

    /// Returns the contents (child URLs) of a directory.
    public func contentsOfDirectory(at url: URL) throws -> [URL] {
        return try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
    }

    /// Returns the total allocated size of a single file.
    public func fileSize(at url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]) else {
            return 0
        }
        return Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
    }

    /// Calculates the total size of a directory recursively.
    public func directorySize(at url: URL) async -> Int64 {
        return await FileEnumerator.directorySize(url)
    }

    /// Reveals a file or directory in Finder.
    @MainActor
    public func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
