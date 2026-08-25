import Foundation
import OSLog

/// Scans user directories for files exceeding a configurable size threshold.
public final class LargeFileService: Sendable {
    public init() {}

    /// Discovers large files in the given directories.
    public func findLargeFiles(
        in directories: [URL]? = nil,
        threshold: Int64 = AppConstants.Defaults.largeFileThreshold
    ) async -> [LargeFile] {
        let searchDirs = directories ?? FileAccessManager.shared.scannableRoots
        var largeFiles: [LargeFile] = []

        for dir in searchDirs {
            guard FileManager.default.fileExists(atPath: dir.path) else { continue }

            for await metadata in FileEnumerator.enumerate(directory: dir, includeHidden: false) {
                if Task.isCancelled { return largeFiles }
                guard !metadata.isDirectory && metadata.size >= threshold else { continue }

                let fileType = metadata.url.pathExtension.isEmpty ? "Unknown" : metadata.url.pathExtension.uppercased()

                largeFiles.append(LargeFile(
                    url: metadata.url,
                    size: metadata.size,
                    modificationDate: metadata.modificationDate,
                    fileType: fileType
                ))
            }
        }

        largeFiles.sort { $0.size > $1.size }
        Logger.scanner.info("Large file scan complete: \(largeFiles.count) files found above \(ByteFormatter.format(threshold))")
        return largeFiles
    }
}
