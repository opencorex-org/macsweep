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
            (home.appendingPathComponent(".gradle/daemon"), "Gradle Daemon Logs"),
            (home.appendingPathComponent(".gradle/native"), "Gradle Native Cache"),
            (home.appendingPathComponent(".android/build-cache"), "Android Build Cache"),
            (home.appendingPathComponent(".android/cache"), "Android SDK Cache"),
            (home.appendingPathComponent(".android/avd"), "Android AVD Cache")
        ]
    }

    public func scan(onProgress: (@Sendable (String) -> Void)? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []

        for (path, label) in targetPaths {
            guard fileManager.fileExists(atPath: path.path) else { continue }
            onProgress?(path.path)
            Logger.scanner.debug("Scanning Gradle path: \(label)")

            let size = await FileEnumerator.directorySize(path, onProgress: onProgress)
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
