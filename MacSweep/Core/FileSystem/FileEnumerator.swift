import Foundation
import OSLog

/// Provides async file system enumeration using FileManager.DirectoryEnumerator.
/// Gracefully skips permission-denied and inaccessible paths.
public struct FileEnumerator: Sendable {
    /// Enumerates all files within a directory, yielding metadata for each file found.
    /// - Parameters:
    ///   - directoryURL: The root directory to enumerate.
    ///   - includeHidden: Whether to include hidden files.
    ///   - skipPackageDescendants: Whether to skip inside app bundles/packages.
    /// - Returns: An async sequence of `FileMetadata` objects.
    public static func enumerate(
        directory directoryURL: URL,
        includeHidden: Bool = false,
        skipPackageDescendants: Bool = true
    ) -> AsyncStream<FileMetadata> {
        AsyncStream { continuation in
            Task.detached(priority: .userInitiated) {
                let fileManager = FileManager.default

                var options: FileManager.DirectoryEnumerationOptions = [.producesRelativePathURLs]
                if !includeHidden {
                    options.insert(.skipsHiddenFiles)
                }
                if skipPackageDescendants {
                    options.insert(.skipsPackageDescendants)
                }

                guard let enumerator = fileManager.enumerator(
                    at: directoryURL,
                    includingPropertiesForKeys: [
                        .fileSizeKey,
                        .totalFileAllocatedSizeKey,
                        .isDirectoryKey,
                        .isSymbolicLinkKey,
                        .contentModificationDateKey,
                        .isHiddenKey
                    ],
                    options: options,
                    errorHandler: { url, error in
                        Logger.fileSystem.debug("Enumeration skipped \(url.path, privacy: .private): \(error.localizedDescription)")
                        return true // Continue enumeration
                    }
                ) else {
                    Logger.fileSystem.warning("Failed to create enumerator for: \(directoryURL.path, privacy: .private)")
                    continuation.finish()
                    return
                }

                for case let fileURL as URL in enumerator {
                    if Task.isCancelled {
                        break
                    }
                    if let metadata = FileMetadata.from(fileURL) {
                        continuation.yield(metadata)
                    }
                }

                continuation.finish()
            }
        }
    }

    /// Calculates the total size of a directory by summing all contained file sizes.
    public static func directorySize(_ url: URL) async -> Int64 {
        var totalSize: Int64 = 0

        for await metadata in enumerate(directory: url, includeHidden: true) {
            if !metadata.isDirectory {
                totalSize += metadata.size
            }
        }

        return totalSize
    }
}
