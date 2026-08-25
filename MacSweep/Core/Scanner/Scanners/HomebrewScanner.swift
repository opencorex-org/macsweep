import Foundation
import OSLog

/// Scans Homebrew download and formula caches.
public struct HomebrewScanner: Sendable {
    private let fileManager = FileManager.default

    private var targetPaths: [(URL, String)] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            (home.appendingPathComponent("Library/Caches/Homebrew"), "Homebrew Cache"),
            (home.appendingPathComponent("Library/Logs/Homebrew"), "Homebrew Logs")
        ]
    }

    public func scan(onProgress: (@Sendable (String) -> Void)? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []

        for (path, label) in targetPaths {
            guard fileManager.fileExists(atPath: path.path) else { continue }
            onProgress?(path.path)
            Logger.scanner.debug("Scanning Homebrew path: \(label)")

            let size = await FileEnumerator.directorySize(path, onProgress: onProgress)
            guard size > 0 else { continue }

            let modDate = (try? path.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast

            items.append(ScanItem(
                url: path,
                size: size,
                category: .developerHomebrew,
                isDirectory: true,
                modificationDate: modDate
            ))
        }

        Logger.scanner.info("Homebrew scan complete: \(items.count) items")
        return items
    }
}
