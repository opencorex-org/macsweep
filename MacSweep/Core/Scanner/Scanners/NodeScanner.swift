import Foundation
import OSLog

/// Scans Node.js ecosystem caches (npm, pnpm, Yarn, Bun).
public nonisolated struct NodeScanner: Sendable {
    private var fileManager: FileManager { .default }

    private var targetPaths: [(URL, String)] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            (home.appendingPathComponent(".npm/_cacache"), "npm Cache"),
            (home.appendingPathComponent(".npm/_logs"), "npm Logs"),
            (home.appendingPathComponent("Library/pnpm/store"), "pnpm Store"),
            (home.appendingPathComponent(".local/share/pnpm/store"), "pnpm Store (XDG)"),
            (home.appendingPathComponent("Library/Caches/Yarn"), "Yarn Cache"),
            (home.appendingPathComponent(".bun/install/cache"), "Bun Cache")
        ]
    }

    @concurrent
    public func scan(onProgress: (@Sendable (String) -> Void)? = nil, control: ScanControl? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []

        for (path, label) in targetPaths {
            guard await control?.waitUntilRunnable() ?? !Task.isCancelled else { return items }
            guard fileManager.fileExists(atPath: path.path) else { continue }
            onProgress?(path.path)
            Logger.scanner.debug("Scanning Node path: \(label)")

            let size = await FileEnumerator.directorySize(path, onProgress: onProgress, control: control)
            guard size > 0 else { continue }

            let modDate = (try? path.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast

            items.append(ScanItem(
                url: path,
                size: size,
                category: .developerNode,
                isDirectory: true,
                modificationDate: modDate
            ))
        }

        Logger.scanner.info("Node scan complete: \(items.count) items")
        return items
    }
}
