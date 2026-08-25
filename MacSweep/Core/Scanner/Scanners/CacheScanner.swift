import Foundation
import OSLog

/// Scans user and system cache directories for reclaimable temporary files.
public struct CacheScanner: Sendable {
    private let fileManager = FileManager.default

    /// Target cache directories to scan.
    private var cacheDirectories: [URL] {
        let home = fileManager.homeDirectoryForCurrentUser
        let library = home.appendingPathComponent("Library")
        return [
            library.appendingPathComponent("Caches"),
            home.appendingPathComponent(".cache")
        ]
    }

    /// Scans cache directories and returns discovered cleanable items.
    public func scan(onProgress: (@Sendable (String) -> Void)? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []

        for cacheDir in cacheDirectories {
            guard fileManager.fileExists(atPath: cacheDir.path) else { continue }
            onProgress?(cacheDir.path)
            Logger.scanner.debug("Scanning cache directory: \(cacheDir.path, privacy: .private)")

            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: cacheDir,
                    includingPropertiesForKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey, .contentModificationDateKey],
                    options: [.skipsHiddenFiles]
                )

                for itemURL in contents {
                    if Task.isCancelled { return items }
                    onProgress?(itemURL.path)

                    let values = try? itemURL.resourceValues(forKeys: [.isDirectoryKey])
                    let isDir = values?.isDirectory ?? false
                    let size: Int64

                    if isDir {
                        size = await FileEnumerator.directorySize(itemURL, onProgress: onProgress)
                    } else {
                        let fileValues = try? itemURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
                        size = Int64(fileValues?.totalFileAllocatedSize ?? fileValues?.fileSize ?? 0)
                    }

                    guard size > 0 else { continue }

                    let modDate = (try? itemURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast

                    items.append(ScanItem(
                        url: itemURL,
                        size: size,
                        category: .systemCache,
                        isDirectory: isDir,
                        modificationDate: modDate
                    ))
                }
            } catch {
                Logger.scanner.warning("Failed to enumerate cache directory: \(error.localizedDescription)")
            }
        }

        Logger.scanner.info("Cache scan complete: \(items.count) items, \(ByteFormatter.format(items.reduce(0) { $0 + $1.size }))")
        return items
    }
}
