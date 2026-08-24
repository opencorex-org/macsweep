import Foundation
import OSLog

/// Scans Gradle and Android build caches for reclaimable artifacts.
public struct GradleScanner: Sendable {
    private let fileManager = FileManager.default

    private var targetPaths: [(URL, String)] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            (home.appendingPathComponent(".gradle/caches"), "Gradle Caches"),
            (home.appendingPathComponent(".gradle/wrapper/dists"), "Gradle Wrapper Distributions"),
            (home.appendingPathComponent(".android/build-cache"), "Android Build Cache"),
            (home.appendingPathComponent(".android/cache"), "Android SDK Cache")
        ]
    }

    public func scan() async -> [ScanItem] {
        var items: [ScanItem] = []

        for (path, label) in targetPaths {
            guard fileManager.fileExists(atPath: path.path) else { continue }
            Logger.scanner.debug("Scanning Gradle path: \(label)")

            let size = await FileEnumerator.directorySize(path)
            guard size > 0 else { continue }

            let modDate = (try? path.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast

            items.append(ScanItem(
                url: path,
                size: size,
                category: .developerGradle,
                isDirectory: true,
                modificationDate: modDate
            ))
        }

        Logger.scanner.info("Gradle scan complete: \(items.count) items")
        return items
    }
}
