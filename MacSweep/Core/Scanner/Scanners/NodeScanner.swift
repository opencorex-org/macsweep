import Foundation
import OSLog

/// Scans Node.js ecosystem caches (npm, pnpm, Yarn, Bun).
public struct NodeScanner: Sendable {
    private let fileManager = FileManager.default

    private var targetPaths: [(URL, String)] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            (home.appendingPathComponent(".npm/_cacache"), "npm Cache"),
            (home.appendingPathComponent("Library/Caches/Yarn"), "Yarn Cache"),
            (home.appendingPathComponent("Library/pnpm/store"), "pnpm Store"),
            (home.appendingPathComponent(".local/share/pnpm/store"), "pnpm Store (XDG)"),
            (home.appendingPathComponent(".bun/install/cache"), "Bun Cache")
        ]
    }

    public func scan() async -> [ScanItem] {
        var items: [ScanItem] = []

        for (path, label) in targetPaths {
            guard fileManager.fileExists(atPath: path.path) else { continue }
            Logger.scanner.debug("Scanning Node path: \(label)")

            let size = await FileEnumerator.directorySize(path)
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
