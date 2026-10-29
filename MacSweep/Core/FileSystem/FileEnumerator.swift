import Foundation
import OSLog

/// Provides async file system enumeration using FileManager.DirectoryEnumerator.
/// Gracefully skips permission-denied and inaccessible paths.
public nonisolated struct FileEnumerator: Sendable {
    /// Enumerates all files within a directory, yielding metadata for each file found.
    /// - Parameters:
    ///   - directoryURL: The root directory to enumerate.
    ///   - includeHidden: Whether to include hidden files.
    ///   - skipPackageDescendants: Whether to skip inside app bundles/packages.
    /// - Returns: An async sequence of `FileMetadata` objects.
    public static func enumerate(
        directory directoryURL: URL,
        includeHidden: Bool = false,
        skipPackageDescendants: Bool = true,
        control: ScanControl? = nil
    ) -> AsyncStream<FileMetadata> {
        let worker = EnumerationWorker(
            directoryURL: directoryURL,
            includeHidden: includeHidden,
            skipPackageDescendants: skipPackageDescendants,
            control: control
        )
        // Pull one entry at a time. A detached producer with unbounded buffering
        // can walk far ahead of consumers and keep running after they stop.
        return AsyncStream(unfolding: { await worker.next() })
    }

    private actor EnumerationWorker {
        let directoryURL: URL
        let includeHidden: Bool
        let skipPackageDescendants: Bool
        let control: ScanControl?
        var enumerator: FileManager.DirectoryEnumerator?
        var started = false

        init(directoryURL: URL, includeHidden: Bool, skipPackageDescendants: Bool, control: ScanControl?) {
            self.directoryURL = directoryURL
            self.includeHidden = includeHidden
            self.skipPackageDescendants = skipPackageDescendants
            self.control = control
        }

        func next() async -> FileMetadata? {
            guard !Task.isCancelled, await control?.waitUntilRunnable() ?? true else { return nil }
            if !started {
                started = true
                var options: FileManager.DirectoryEnumerationOptions = []
                if !includeHidden { options.insert(.skipsHiddenFiles) }
                if skipPackageDescendants { options.insert(.skipsPackageDescendants) }
                enumerator = FileManager.default.enumerator(
                    at: directoryURL,
                    includingPropertiesForKeys: [
                        .fileSizeKey, .totalFileAllocatedSizeKey, .isDirectoryKey,
                        .isSymbolicLinkKey, .contentModificationDateKey, .isHiddenKey
                    ],
                    options: options,
                    errorHandler: { url, error in
                        Logger.fileSystem.debug("Enumeration skipped \(url.path, privacy: .private): \(error.localizedDescription)")
                        return true
                    }
                )
            }
            while !Task.isCancelled, control?.isCancelled != true,
                  let url = enumerator?.nextObject() as? URL {
                if let metadata = autoreleasepool(invoking: { FileMetadata.from(url) }) {
                    return metadata
                }
            }
            enumerator = nil
            return nil
        }
    }

    /// Calculates the total size of a directory by summing all contained file sizes.
    /// - Parameter onProgress: Optional closure called periodically with active file path.
    @concurrent
    public static func directorySize(
        _ url: URL,
        onProgress: (@Sendable (String) -> Void)? = nil,
        control: ScanControl? = nil
    ) async -> Int64 {
        guard !Task.isCancelled, await control?.waitUntilRunnable() ?? true else { return 0 }
        // Size-only scans avoid an unbounded AsyncStream and one actor hop per file.
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey, .fileSizeKey],
            options: [],
            errorHandler: { _, _ in true }
        ) else { return 0 }

        var totalSize: Int64 = 0
        var lastProgress = ContinuousClock.now
        while !Task.isCancelled {
            if let control, !(await control.waitUntilRunnable()) { break }
            guard let fileURL = enumerator.nextObject() as? URL else { break }
            autoreleasepool {
                if let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey, .fileSizeKey]),
                   values.isDirectory != true {
                    totalSize += Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
                }
            }
            let now = ContinuousClock.now
            if now - lastProgress >= .milliseconds(100) {
                onProgress?(fileURL.path)
                lastProgress = now
            }
        }
        return totalSize
    }
}
