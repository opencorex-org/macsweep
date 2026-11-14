import Foundation

public actor MaintenanceInsightsService {
    private let fileManager = FileManager.default
    private let duplicateService = DuplicateDetectionService()

    public init() {}

    public func scan(ignoredPaths: [String]) async -> [MaintenanceInsight] {
        let home = fileManager.homeDirectoryForCurrentUser
        var results: [MaintenanceInsight] = []
        results += inspectFiles(in: [home.appending(path: "Downloads"), home.appending(path: "Desktop")], ignoredPaths: ignoredPaths)
        results += inspectCaches(home: home, ignoredPaths: ignoredPaths)
        results += inspectApplications(home: home, ignoredPaths: ignoredPaths)
        results += await inspectSnapshots()
        return results.sorted { ($0.size, $0.name) > ($1.size, $1.name) }
    }

    public func duplicatePhotos(ignoredPaths: [String]) async -> [DuplicateGroup] {
        let home = fileManager.homeDirectoryForCurrentUser
        let roots = [home.appending(path: "Pictures"), home.appending(path: "Desktop")]
            .filter { !isIgnored($0, ignoredPaths: ignoredPaths) && fileManager.fileExists(atPath: $0.path) }
        return await duplicateService.findDuplicates(
            in: roots,
            allowedExtensions: ["png", "jpg", "jpeg", "heic", "tiff", "webp"]
        )
    }

    private func inspectFiles(in roots: [URL], ignoredPaths: [String]) -> [MaintenanceInsight] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]
        let imageExtensions = Set(["png", "jpg", "jpeg", "heic", "tiff", "webp"])
        let installerExtensions = Set(["dmg", "pkg", "zip"])
        let now = Date()
        var output: [MaintenanceInsight] = []

        for root in roots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            for case let url as URL in enumerator {
                if isIgnored(url, ignoredPaths: ignoredPaths) { enumerator.skipDescendants(); continue }
                guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true else { continue }
                let size = Int64(values.fileSize ?? 0)
                let date = values.contentModificationDate
                let lowerName = url.lastPathComponent.lowercased()
                let ext = url.pathExtension.lowercased()
                let age = now.timeIntervalSince(date ?? now)

                if size >= 100_000_000, age <= 30 * 86_400 {
                    output.append(.init(kind: .recentFile, name: url.lastPathComponent, url: url, size: size, date: date, detail: "Large file added or changed in the last 30 days"))
                }
                if installerExtensions.contains(ext), age >= 30 * 86_400 {
                    output.append(.init(kind: .installer, name: url.lastPathComponent, url: url, size: size, date: date, detail: "Installer archive older than 30 days"))
                }
                if imageExtensions.contains(ext), lowerName.contains("screenshot") || lowerName.contains("screen shot") || lowerName.contains("screen capture") {
                    output.append(.init(kind: .screenshot, name: url.lastPathComponent, url: url, size: size, date: date, detail: "Screenshot candidate for review"))
                }
            }
        }
        return output
    }

    private func inspectCaches(home: URL, ignoredPaths: [String]) -> [MaintenanceInsight] {
        let cacheRoot = home.appending(path: "Library/Caches")
        let browserNames = ["com.apple.Safari", "Google", "org.mozilla", "Firefox", "Microsoft Edge", "BraveSoftware"]
        guard let children = try? fileManager.contentsOfDirectory(at: cacheRoot, includingPropertiesForKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey], options: [.skipsHiddenFiles]) else { return [] }
        return children.compactMap { url in
            guard !isIgnored(url, ignoredPaths: ignoredPaths) else { return nil }
            let size = directorySize(url, limit: 1_000_000_000_000)
            guard size > 0 else { return nil }
            let isBrowser = browserNames.contains { url.lastPathComponent.localizedCaseInsensitiveContains($0) }
            return MaintenanceInsight(
                kind: isBrowser ? .browserCache : .appCache,
                name: url.lastPathComponent,
                url: url,
                size: size,
                detail: isBrowser ? "Per-browser cache; sign-in data is not selected" : "Application-created cache data"
            )
        }
    }

    private func inspectApplications(home: URL, ignoredPaths: [String]) -> [MaintenanceInsight] {
        let roots = [URL(filePath: "/Applications"), home.appending(path: "Applications")]
        let cutoff = Date().addingTimeInterval(-120 * 86_400)
        var output: [MaintenanceInsight] = []
        for root in roots {
            guard let apps = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentAccessDateKey, .contentModificationDateKey, .fileAllocatedSizeKey], options: [.skipsHiddenFiles]) else { continue }
            for app in apps where app.pathExtension.lowercased() == "app" && !isIgnored(app, ignoredPaths: ignoredPaths) {
                let values = try? app.resourceValues(forKeys: [.contentAccessDateKey, .contentModificationDateKey, .fileAllocatedSizeKey])
                let lastUsed = values?.contentAccessDate ?? values?.contentModificationDate
                guard let lastUsed, lastUsed < cutoff else { continue }
                output.append(.init(kind: .unusedApp, name: app.deletingPathExtension().lastPathComponent, url: app, size: Int64(values?.fileAllocatedSize ?? 0), date: lastUsed, detail: "Not accessed for at least 120 days; review before uninstalling"))
            }
        }
        return output
    }

    private func inspectSnapshots() async -> [MaintenanceInsight] {
        guard let output = try? await ProcessRunner.run(executableURL: URL(filePath: "/usr/bin/tmutil"), arguments: ["listlocalsnapshots", "/"]) else { return [] }
        return output.split(separator: "\n").compactMap { line in
            let value = String(line)
            guard value.contains("com.apple.TimeMachine") else { return nil }
            return .init(kind: .snapshot, name: value.components(separatedBy: ".").last ?? value, detail: "Managed by macOS; open Time Machine settings to review")
        }
    }

    private func directorySize(_ root: URL, limit: Int64) -> Int64 {
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
        guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: Set(keys))
            if values?.isRegularFile == true { total += Int64(values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? 0) }
            if total >= limit { break }
        }
        return total
    }

    private func isIgnored(_ url: URL, ignoredPaths: [String]) -> Bool {
        let path = url.standardizedFileURL.path
        return ignoredPaths.contains { path == $0 || path.hasPrefix($0 + "/") }
    }
}
