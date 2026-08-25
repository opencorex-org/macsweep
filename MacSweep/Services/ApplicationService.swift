import Foundation
import OSLog

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

        return ApplicationInfo(
            bundleIdentifier: bundleID,
            name: name,
            bundleURL: bundleURL,
            version: version,
            bundleSize: bundleSize
        )
    }
}
