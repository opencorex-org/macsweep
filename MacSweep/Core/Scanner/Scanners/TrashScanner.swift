import Foundation
import OSLog

/// Scans the user's Trash directory for reclaimable items.
public struct TrashScanner: Sendable {
    private let fileManager = FileManager.default

    private var trashURL: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
    }

    public func scan() async -> [ScanItem] {
        var items: [ScanItem] = []

        guard fileManager.fileExists(atPath: trashURL.path) else { return items }
        Logger.scanner.debug("Scanning Trash directory")

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: trashURL,
                includingPropertiesForKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey, .contentModificationDateKey],
                options: []
            )

            for itemURL in contents {
                if Task.isCancelled { return items }

                let values = try? itemURL.resourceValues(forKeys: [.isDirectoryKey])
                let isDir = values?.isDirectory ?? false
                let size: Int64

                if isDir {
                    size = await FileEnumerator.directorySize(itemURL)
                } else {
                    let fileValues = try? itemURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
                    size = Int64(fileValues?.totalFileAllocatedSize ?? fileValues?.fileSize ?? 0)
                }

                guard size > 0 else { continue }

                let modDate = (try? itemURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast

                items.append(ScanItem(
                    url: itemURL,
                    size: size,
                    category: .trash,
                    isDirectory: isDir,
                    modificationDate: modDate
                ))
            }
        } catch {
            Logger.scanner.warning("Failed to enumerate Trash: \(error.localizedDescription)")
        }

        Logger.scanner.info("Trash scan complete: \(items.count) items")
        return items
    }
}
