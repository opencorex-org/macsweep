import Foundation
import OSLog

public struct LargeFileScanProgress: Sendable {
    public let currentPath: String
    public let scannedFilesCount: Int
    public let foundFilesCount: Int
    public let foundBytes: Int64
    public let completedRootsCount: Int
    public let totalRootsCount: Int

    public var fractionCompleted: Double {
        guard totalRootsCount > 0 else { return 0 }
        return min(Double(completedRootsCount) / Double(totalRootsCount), 1)
    }
}

public struct LargeFileScanResult: Sendable {
    public let files: [LargeFile]
    public let scannedRoots: [URL]
    public let inaccessibleRoots: [URL]
}

/// Scans user directories for files exceeding a configurable size threshold.
public final class LargeFileService: Sendable {
    public init() {}

    /// Discovers large files in the given directories.
    public func findLargeFiles(
        in directories: [URL]? = nil,
        threshold: Int64 = AppConstants.Defaults.largeFileThreshold,
        progressHandler: @escaping @Sendable (LargeFileScanProgress) -> Void = { _ in }
    ) async -> LargeFileScanResult {
        let searchDirs = directories ?? FileAccessManager.shared.scannableRoots
        var largeFiles: [LargeFile] = []
        var scannedRoots: [URL] = []
        var inaccessibleRoots: [URL] = []
        var scannedFilesCount = 0
        var foundBytes: Int64 = 0

        for (rootIndex, dir) in searchDirs.enumerated() {
            guard FileManager.default.fileExists(atPath: dir.path) else {
                progressHandler(LargeFileScanProgress(
                    currentPath: dir.path,
                    scannedFilesCount: scannedFilesCount,
                    foundFilesCount: largeFiles.count,
                    foundBytes: foundBytes,
                    completedRootsCount: rootIndex + 1,
                    totalRootsCount: searchDirs.count
                ))
                continue
            }

            do {
                _ = try FileManager.default.contentsOfDirectory(
                    at: dir,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
            } catch {
                inaccessibleRoots.append(dir)
                Logger.permissions.warning("Large file root inaccessible: \(dir.path, privacy: .private) — \(error.localizedDescription)")
                progressHandler(LargeFileScanProgress(
                    currentPath: dir.path,
                    scannedFilesCount: scannedFilesCount,
                    foundFilesCount: largeFiles.count,
                    foundBytes: foundBytes,
                    completedRootsCount: rootIndex + 1,
                    totalRootsCount: searchDirs.count
                ))
                continue
            }

            scannedRoots.append(dir)

            for await metadata in FileEnumerator.enumerate(directory: dir, includeHidden: false) {
                if Task.isCancelled {
                    return LargeFileScanResult(
                        files: largeFiles,
                        scannedRoots: scannedRoots,
                        inaccessibleRoots: inaccessibleRoots
                    )
                }
                guard !metadata.isDirectory else { continue }
                scannedFilesCount += 1

                if scannedFilesCount.isMultiple(of: 100) {
                    progressHandler(LargeFileScanProgress(
                        currentPath: metadata.url.path,
                        scannedFilesCount: scannedFilesCount,
                        foundFilesCount: largeFiles.count,
                        foundBytes: foundBytes,
                        completedRootsCount: rootIndex,
                        totalRootsCount: searchDirs.count
                    ))
                }

                guard metadata.size >= threshold else { continue }

                let fileType = metadata.url.pathExtension.isEmpty ? "Unknown" : metadata.url.pathExtension.uppercased()

                largeFiles.append(LargeFile(
                    url: metadata.url,
                    size: metadata.size,
                    modificationDate: metadata.modificationDate,
                    fileType: fileType
                ))
                foundBytes += metadata.size
            }

            progressHandler(LargeFileScanProgress(
                currentPath: dir.path,
                scannedFilesCount: scannedFilesCount,
                foundFilesCount: largeFiles.count,
                foundBytes: foundBytes,
                completedRootsCount: rootIndex + 1,
                totalRootsCount: searchDirs.count
            ))
        }

        largeFiles.sort { $0.size > $1.size }
        Logger.scanner.info("Large file scan complete: \(largeFiles.count) files found above \(ByteFormatter.format(threshold))")
        return LargeFileScanResult(
            files: largeFiles,
            scannedRoots: scannedRoots,
            inaccessibleRoots: inaccessibleRoots
        )
    }
}
