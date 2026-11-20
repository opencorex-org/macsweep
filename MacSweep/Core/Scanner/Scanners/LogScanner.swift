import Foundation
import OSLog

/// Scans user log directories for reclaimable log files.
public nonisolated struct LogScanner: Sendable {
    private var fileManager: FileManager { .default }

    private var logDirectories: [URL] {
        let home = fileManager.homeDirectoryForCurrentUser
        let library = home.appendingPathComponent("Library")
        var directories = [library.appendingPathComponent("Logs")]
        directories += nestedLogDirectories(
            in: library.appendingPathComponent("Containers"),
            logPath: "Data/Library/Logs"
        )
        directories += nestedLogDirectories(
            in: library.appendingPathComponent("Group Containers"),
            logPath: "Library/Logs"
        )

        var seenPaths = Set<String>()
        return directories.filter { seenPaths.insert($0.standardizedFileURL.path).inserted }
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

                let safeBefore = Date().addingTimeInterval(-7 * 24 * 60 * 60)

                items.append(ScanItem(
                    url: metadata.url,
                    size: metadata.size,
                    category: .userLogs,
                    risk: metadata.modificationDate <= safeBefore ? .safe : .caution,
                    isDirectory: false,
                    modificationDate: metadata.modificationDate
                ))
            }
        }

        Logger.scanner.info("Log scan complete: \(items.count) items")
        return items
    }

    private func nestedLogDirectories(in containerRoot: URL, logPath: String) -> [URL] {
        guard let containers = try? fileManager.contentsOfDirectory(
            at: containerRoot,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return containers.compactMap { container in
            let containerValues = try? container.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard containerValues?.isDirectory == true,
                  containerValues?.isSymbolicLink != true else { return nil }

            let logsURL = container.appendingPathComponent(logPath, isDirectory: true)
            let logValues = try? logsURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard logValues?.isDirectory == true,
                  logValues?.isSymbolicLink != true else { return nil }
            return logsURL
        }
    }
}
