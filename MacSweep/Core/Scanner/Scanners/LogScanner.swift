import Foundation
import OSLog

/// Scans user log directories for reclaimable log files.
public nonisolated struct LogScanner: Sendable {
    private var fileManager: FileManager { .default }

    private var logDirectories: [URL] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Library/Logs")
        ]
    }

    @concurrent
    public func scan(onProgress: (@Sendable (String) -> Void)? = nil, control: ScanControl? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []

        for logDir in logDirectories {
            guard await control?.waitUntilRunnable() ?? !Task.isCancelled else { return items }
            guard fileManager.fileExists(atPath: logDir.path) else { continue }
            onProgress?(logDir.path)
            Logger.scanner.debug("Scanning log directory: \(logDir.path, privacy: .private)")

            for await metadata in FileEnumerator.enumerate(directory: logDir, includeHidden: false, control: control) {
                guard await control?.waitUntilRunnable() ?? !Task.isCancelled else { return items }
                onProgress?(metadata.url.path)
                guard !metadata.isDirectory && metadata.size > 0 else { continue }

                let ext = metadata.url.pathExtension.lowercased()
                guard ["log", "txt", "crash", "diag", "ips", "spin"].contains(ext) else { continue }

                items.append(ScanItem(
                    url: metadata.url,
                    size: metadata.size,
                    category: .userLogs,
                    isDirectory: false,
                    modificationDate: metadata.modificationDate
                ))
            }
        }

        Logger.scanner.info("Log scan complete: \(items.count) items")
        return items
    }
}
