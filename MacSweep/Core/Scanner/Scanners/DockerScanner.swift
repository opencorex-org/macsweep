import Foundation
import OSLog

/// Scans Docker Desktop build caches and data.
public struct DockerScanner: Sendable {
    private let fileManager = FileManager.default

    private var targetPaths: [(URL, String)] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            (home.appendingPathComponent("Library/Containers/com.docker.docker/Data"), "Docker Data"),
            (home.appendingPathComponent(".docker"), "Docker Config")
        ]
    }

    public func scan() async -> [ScanItem] {
        var items: [ScanItem] = []

        for (path, label) in targetPaths {
            guard fileManager.fileExists(atPath: path.path) else { continue }
            Logger.scanner.debug("Scanning Docker path: \(label)")

            let size = await FileEnumerator.directorySize(path)
            guard size > 0 else { continue }

            let modDate = (try? path.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast

            items.append(ScanItem(
                url: path,
                size: size,
                category: .developerDocker,
                isDirectory: true,
                modificationDate: modDate
            ))
        }

        Logger.scanner.info("Docker scan complete: \(items.count) items")
        return items
    }
}
