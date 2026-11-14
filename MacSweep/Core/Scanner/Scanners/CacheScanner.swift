import Foundation
import OSLog

/// Scans user and system cache directories for reclaimable temporary files.
public nonisolated struct CacheScanner: Sendable {
    private var fileManager: FileManager { .default }

    private struct CacheLocation: Sendable {
        let url: URL
        let recommendedAge: TimeInterval
    }

    /// User-owned cache roots. Their contents are scanned, but the roots themselves
    /// are never offered for deletion so apps can safely recreate cache data.
    private var cacheLocations: [CacheLocation] {
        let home = fileManager.homeDirectoryForCurrentUser
        let library = home.appendingPathComponent("Library")
        let oneDay: TimeInterval = 24 * 60 * 60
        let sevenDays: TimeInterval = 7 * oneDay
        var locations = [
            CacheLocation(url: library.appendingPathComponent("Caches"), recommendedAge: oneDay),
            CacheLocation(url: home.appendingPathComponent(".cache"), recommendedAge: oneDay)
        ]

        locations += nestedCacheLocations(
            in: library.appendingPathComponent("Containers"),
            cachePath: "Data/Library/Caches",
            recommendedAge: oneDay
        )
        locations += nestedCacheLocations(
            in: library.appendingPathComponent("Group Containers"),
            cachePath: "Library/Caches",
            recommendedAge: oneDay
        )

        // macOS normally purges this user-specific temporary directory at restart.
        // Only old entries are recommended automatically; recent ones require review.
        let temporaryDirectory = fileManager.temporaryDirectory.standardizedFileURL
        if temporaryDirectory.path.hasPrefix("/var/folders/") ||
            temporaryDirectory.path.hasPrefix("/private/var/folders/") {
            locations.append(CacheLocation(url: temporaryDirectory, recommendedAge: sevenDays))
            let systemCacheDirectory = temporaryDirectory
                .deletingLastPathComponent()
                .appendingPathComponent("C", isDirectory: true)
            locations.append(CacheLocation(url: systemCacheDirectory, recommendedAge: sevenDays))
        }

        var seenPaths = Set<String>()
        return locations.filter { seenPaths.insert($0.url.standardizedFileURL.path).inserted }
    }

    /// Scans cache directories and returns discovered cleanable items.
    @concurrent
    public func scan(onProgress: (@Sendable (String) -> Void)? = nil, control: ScanControl? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []

        for location in cacheLocations {
            guard await control?.waitUntilRunnable() ?? !Task.isCancelled else { return items }
            let cacheDir = location.url
            let rootValues = try? cacheDir.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard rootValues?.isDirectory == true, rootValues?.isSymbolicLink != true else { continue }
            onProgress?(cacheDir.path)
            Logger.scanner.debug("Scanning cache directory: \(cacheDir.path, privacy: .private)")

            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: cacheDir,
                    includingPropertiesForKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey, .contentModificationDateKey],
                    options: []
                )

                for itemURL in contents {
                    guard await control?.waitUntilRunnable() ?? !Task.isCancelled else { return items }
                    onProgress?(itemURL.path)

                    let values = try? itemURL.resourceValues(forKeys: [
                        .isDirectoryKey,
                        .isSymbolicLinkKey,
                        .contentModificationDateKey
                    ])
                    guard values?.isSymbolicLink != true else { continue }
                    let isDir = values?.isDirectory ?? false
                    let size: Int64

                    if isDir {
                        size = await FileEnumerator.directorySize(itemURL, onProgress: onProgress, control: control)
                    } else {
                        let fileValues = try? itemURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
                        size = Int64(fileValues?.totalFileAllocatedSize ?? fileValues?.fileSize ?? 0)
                    }

                    guard size > 0 else { continue }

                    let modDate = values?.contentModificationDate ?? Date.distantPast
                    let recommendedBefore = Date().addingTimeInterval(-location.recommendedAge)

                    items.append(ScanItem(
                        url: itemURL,
                        size: size,
                        category: .systemCache,
                        risk: modDate <= recommendedBefore ? .safe : .caution,
                        isDirectory: isDir,
                        modificationDate: modDate
                    ))
                }
            } catch {
                Logger.scanner.warning("Failed to enumerate cache directory: \(error.localizedDescription)")
            }
        }

        Logger.scanner.info("Cache scan complete: \(items.count) items, \(ByteFormatter.format(items.reduce(0) { $0 + $1.size }))")
        return items
    }

    private func nestedCacheLocations(
        in containerRoot: URL,
        cachePath: String,
        recommendedAge: TimeInterval
    ) -> [CacheLocation] {
        guard let containers = try? fileManager.contentsOfDirectory(
            at: containerRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return containers.compactMap { container in
            let containerValues = try? container.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard containerValues?.isDirectory == true,
                  containerValues?.isSymbolicLink != true else { return nil }
            let cacheURL = container.appendingPathComponent(cachePath, isDirectory: true)
            let cacheValues = try? cacheURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard cacheValues?.isDirectory == true,
                  cacheValues?.isSymbolicLink != true else { return nil }
            return CacheLocation(url: cacheURL, recommendedAge: recommendedAge)
        }
    }
}
