import Foundation
import OSLog

/// Scans Node.js ecosystem caches (npm, pnpm, Yarn, Bun).
public struct NodeScanner: Sendable {
    private let fileManager = FileManager.default

    private var targetPaths: [(URL, String)] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            (home.appendingPathComponent(".npm"), "npm Cache & Logs"),
            (home.appendingPathComponent("Library/pnpm"), "pnpm Store & Data"),
            (home.appendingPathComponent(".local/share/pnpm"), "pnpm Data (XDG)"),
            (home.appendingPathComponent("Library/Caches/Yarn"), "Yarn Cache"),
            (home.appendingPathComponent(".bun/install/cache"), "Bun Cache"),
            (home.appendingPathComponent(".bun/install"), "Bun Install Cache")
        ]
    }

    public func scan(onProgress: (@Sendable (String) -> Void)? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []

        for (path, label) in targetPaths {
            guard fileManager.fileExists(atPath: path.path) else { continue }
            onProgress?(path.path)
            Logger.scanner.debug("Scanning Node path: \(label)")

            let size = await FileEnumerator.directorySize(path, onProgress: onProgress)
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
