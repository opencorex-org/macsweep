import Foundation
import OSLog

public struct ApplicationUninstallProgress: Sendable {
    public let applicationName: String
    public let currentItemName: String
    public let completedItemsCount: Int
    public let totalItemsCount: Int
    public let startedAt: Date

    public var fractionCompleted: Double {
        guard totalItemsCount > 0 else { return 0 }
        return min(Double(completedItemsCount) / Double(totalItemsCount), 1)
    }
}

public struct ApplicationUninstallFailure: Sendable {
    public let url: URL
    public let reason: String
}

public struct ApplicationUninstallResult: Sendable {
    public let applicationName: String
    public let appBundleMovedToTrash: Bool
    public let movedItemsCount: Int
    public let totalItemsCount: Int
    public let movedBytes: Int64
    public let failures: [ApplicationUninstallFailure]
    public let duration: TimeInterval

    public var isFullSuccess: Bool { failures.isEmpty && appBundleMovedToTrash }
}

/// Discovers installed macOS applications and scans for associated leftover files.
public final class ApplicationService: Sendable {
    private let fileManager = FileManager.default

    public init() {}

    /// Discovers all installed third-party applications.
    public func discoverApplications() async -> [ApplicationInfo] {
        var apps: [ApplicationInfo] = []
        let appDirs = [
            URL(fileURLWithPath: "/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        for appDir in appDirs {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: appDir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in contents where url.pathExtension == "app" {
                if Task.isCancelled { return apps }
                if let info = await applicationInfo(from: url) {
                    apps.append(info)
                }
            }
        }

        apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return apps
    }

    /// Extracts application metadata from a .app bundle.
    private func applicationInfo(from bundleURL: URL) async -> ApplicationInfo? {
        guard let bundle = Bundle(url: bundleURL) else { return nil }
        let bundleID = bundle.bundleIdentifier ?? ""
        guard !bundleID.hasPrefix("com.apple.") else { return nil } // Skip Apple apps

        let name = bundle.infoDictionary?["CFBundleName"] as? String
            ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
            ?? bundleURL.deletingPathExtension().lastPathComponent

        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let bundleSize = await FileEnumerator.directorySize(bundleURL)
        let leftovers = await discoverLeftovers(bundleIdentifier: bundleID)

        return ApplicationInfo(
            bundleIdentifier: bundleID,
            name: name,
            bundleURL: bundleURL,
            version: version,
            bundleSize: bundleSize,
            leftovers: leftovers
        )
    }

    /// Moves an application and its exact bundle-identifier leftovers to Trash.
    public func uninstall(
        _ app: ApplicationInfo,
        progressHandler: @escaping @MainActor @Sendable (ApplicationUninstallProgress) -> Void = { _ in }
    ) async -> ApplicationUninstallResult {
        let startedAt = Date()
        let targets = [(url: app.bundleURL, name: app.name, size: app.bundleSize, isBundle: true)]
            + app.leftovers.map { (url: $0.url, name: $0.name, size: $0.size, isBundle: false) }

        var movedCount = 0
        var movedBytes: Int64 = 0
        var appBundleMoved = false
        var failures: [ApplicationUninstallFailure] = []

        progressHandler(ApplicationUninstallProgress(
            applicationName: app.name,
            currentItemName: "Preparing uninstall…",
            completedItemsCount: 0,
            totalItemsCount: targets.count,
            startedAt: startedAt
        ))

        for (index, target) in targets.enumerated() {
            if Task.isCancelled { break }

            progressHandler(ApplicationUninstallProgress(
                applicationName: app.name,
                currentItemName: target.name,
                completedItemsCount: index,
                totalItemsCount: targets.count,
                startedAt: startedAt
            ))

            do {
                guard fileManager.fileExists(atPath: target.url.path) else {
                    throw MacSweepError.fileNotFound(path: target.url.path)
                }
                _ = try await TrashService.recycleUsingWorkspace(target.url)
                movedCount += 1
                movedBytes += target.size
                if target.isBundle { appBundleMoved = true }
            } catch {
                failures.append(ApplicationUninstallFailure(
                    url: target.url,
                    reason: error.localizedDescription
                ))
            }

            progressHandler(ApplicationUninstallProgress(
                applicationName: app.name,
                currentItemName: target.name,
                completedItemsCount: index + 1,
                totalItemsCount: targets.count,
                startedAt: startedAt
            ))
            await Task.yield()
        }

        return ApplicationUninstallResult(
            applicationName: app.name,
            appBundleMovedToTrash: appBundleMoved,
            movedItemsCount: movedCount,
            totalItemsCount: targets.count,
            movedBytes: movedBytes,
            failures: failures,
            duration: Date().timeIntervalSince(startedAt)
        )
    }

    private func discoverLeftovers(bundleIdentifier: String) async -> [LeftoverFile] {
        let library = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        let candidates: [(URL, LeftoverType)] = [
            (library.appendingPathComponent("Preferences/\(bundleIdentifier).plist"), .preferences),
            (library.appendingPathComponent("Application Support/\(bundleIdentifier)"), .applicationSupport),
            (library.appendingPathComponent("Caches/\(bundleIdentifier)"), .caches),
            (library.appendingPathComponent("Logs/\(bundleIdentifier)"), .logs),
            (library.appendingPathComponent("Containers/\(bundleIdentifier)"), .containers),
            (library.appendingPathComponent("Saved Application State/\(bundleIdentifier).savedState"), .savedState),
            (library.appendingPathComponent("HTTPStorages/\(bundleIdentifier)"), .httpStorage)
        ]

        var leftovers: [LeftoverFile] = []
        for (url, type) in candidates where fileManager.fileExists(atPath: url.path) {
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey])
            let size: Int64
            if values?.isDirectory == true {
                size = await FileEnumerator.directorySize(url)
            } else {
                size = Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
            }

            leftovers.append(LeftoverFile(url: url, size: size, type: type))
        }
        return leftovers.sorted { $0.size > $1.size }
    }
}
