import AppKit
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

/// Discovers removable macOS applications and strongly-associated support files.
/// Shared directories are never returned unless an entry's name identifies the app.
public final class ApplicationService: Sendable {
    private let fileManager = FileManager.default

    public init() {}

    public func discoverApplications() async -> [ApplicationInfo] {
        var urls = discoverApplicationBundles()
        let runningURLs = await MainActor.run {
            NSWorkspace.shared.runningApplications.compactMap(\.bundleURL)
        }
        urls.formUnion(runningURLs.filter(isRemovableApplication))

        var apps: [ApplicationInfo] = []
        var seenPaths = Set<String>()
        for url in urls.sorted(by: { $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending }) {
            if Task.isCancelled { return apps }
            let resolvedPath = url.resolvingSymlinksInPath().standardizedFileURL.path
            guard seenPaths.insert(resolvedPath).inserted,
                  let info = await applicationInfo(from: url) else { continue }
            apps.append(info)
        }

        apps.sort {
            let comparison = $0.name.localizedCaseInsensitiveCompare($1.name)
            return comparison == .orderedSame ? $0.bundleURL.path < $1.bundleURL.path : comparison == .orderedAscending
        }
        return apps
    }

    public func inspectApplication(at url: URL) async -> ApplicationInfo? {
        await applicationInfo(from: url)
    }

    private func discoverApplicationBundles() -> Set<URL> {
        let home = fileManager.homeDirectoryForCurrentUser
        var roots = [
            URL(filePath: "/Applications"),
            home.appendingPathComponent("Applications"),
            URL(filePath: "/Users/Shared/Applications"),
            URL(filePath: "/opt/homebrew/Caskroom")
        ]

        if let volumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeIsInternalKey, .volumeIsReadOnlyKey],
            options: [.skipHiddenVolumes]
        ) {
            for volume in volumes {
                let values = try? volume.resourceValues(forKeys: [.volumeIsInternalKey, .volumeIsReadOnlyKey])
                guard values?.volumeIsInternal != true, values?.volumeIsReadOnly != true else { continue }
                roots.append(volume.appendingPathComponent("Applications"))
            }
        }

        var results = Set<URL>()
        for root in roots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else { continue }

            for case let url as URL in enumerator where url.pathExtension.lowercased() == "app" {
                if isRemovableApplication(url) { results.insert(url) }
                enumerator.skipDescendants()
            }
        }
        return results
    }

    private func isRemovableApplication(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        guard url.pathExtension.lowercased() == "app" else { return false }
        return !path.hasPrefix("/System/")
            && !path.hasPrefix("/Library/CoreServices/")
            && !path.contains(".app/Contents/")
            && path != Bundle.main.bundleURL.standardizedFileURL.path
    }

    private func applicationInfo(from bundleURL: URL) async -> ApplicationInfo? {
        guard isRemovableApplication(bundleURL) else { return nil }
        let bundle = Bundle(url: bundleURL)
        let info = bundle?.infoDictionary
            ?? (NSDictionary(contentsOf: bundleURL.appendingPathComponent("Contents/Info.plist")) as? [String: Any])

        let bundleID = (info?["CFBundleIdentifier"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = info?["CFBundleDisplayName"] as? String
            ?? info?["CFBundleName"] as? String
            ?? bundleURL.deletingPathExtension().lastPathComponent
        let version = info?["CFBundleShortVersionString"] as? String
            ?? info?["CFBundleVersion"] as? String
            ?? ""
        let bundleSize = await FileEnumerator.directorySize(bundleURL)
        let leftovers = await discoverLeftovers(
            bundleIdentifier: bundleID,
            applicationName: name,
            bundleURL: bundleURL
        )

        return ApplicationInfo(
            bundleIdentifier: bundleID.isEmpty ? "No bundle identifier" : bundleID,
            name: name,
            bundleURL: bundleURL,
            version: version,
            bundleSize: bundleSize,
            leftovers: leftovers
        )
    }

    public func uninstall(
        _ app: ApplicationInfo,
        progressHandler: @escaping @MainActor @Sendable (ApplicationUninstallProgress) -> Void = { _ in }
    ) async -> ApplicationUninstallResult {
        let startedAt = Date()
        let appPath = app.bundleURL.resolvingSymlinksInPath().standardizedFileURL.path
        await MainActor.run {
            for runningApp in NSWorkspace.shared.runningApplications {
                let runningPath = runningApp.bundleURL?.resolvingSymlinksInPath().standardizedFileURL.path
                if runningPath == appPath || (!app.bundleIdentifier.isEmpty && runningApp.bundleIdentifier == app.bundleIdentifier) {
                    runningApp.terminate()
                }
            }
        }
        try? await Task.sleep(for: .milliseconds(400))

        let targets = [(url: app.bundleURL, name: app.name, size: app.bundleSize, isBundle: true)]
            + app.leftovers.map { (url: $0.url, name: $0.name, size: $0.size, isBundle: false) }

        var movedCount = 0
        var movedBytes: Int64 = 0
        var appBundleMoved = false
        var failures: [ApplicationUninstallFailure] = []

        await progressHandler(.init(applicationName: app.name, currentItemName: "Preparing uninstall…", completedItemsCount: 0, totalItemsCount: targets.count, startedAt: startedAt))

        for (index, target) in targets.enumerated() {
            if Task.isCancelled { break }
            await progressHandler(.init(applicationName: app.name, currentItemName: target.name, completedItemsCount: index, totalItemsCount: targets.count, startedAt: startedAt))
            do {
                guard fileManager.fileExists(atPath: target.url.path) else { throw MacSweepError.fileNotFound(path: target.url.path) }
                _ = try await TrashService.recycleUsingWorkspace(target.url)
                movedCount += 1
                movedBytes += target.size
                if target.isBundle { appBundleMoved = true }
            } catch {
                failures.append(.init(url: target.url, reason: error.localizedDescription))
                // Keep settings and user data intact if the application itself
                // could not be removed; this avoids a destructive partial uninstall.
                if target.isBundle { break }
            }
            await progressHandler(.init(applicationName: app.name, currentItemName: target.name, completedItemsCount: index + 1, totalItemsCount: targets.count, startedAt: startedAt))
            await Task.yield()
        }

        return .init(
            applicationName: app.name,
            appBundleMovedToTrash: appBundleMoved,
            movedItemsCount: movedCount,
            totalItemsCount: targets.count,
            movedBytes: movedBytes,
            failures: failures,
            duration: Date().timeIntervalSince(startedAt)
        )
    }

    private func discoverLeftovers(bundleIdentifier: String, applicationName: String, bundleURL: URL) async -> [LeftoverFile] {
        let homeLibrary = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        let systemLibrary = URL(filePath: "/Library")
        var candidates: [(URL, LeftoverType)] = []
        let identifiers = relatedBundleIdentifiers(in: bundleURL, primaryIdentifier: bundleIdentifier)

        for identifier in identifiers {
            candidates += exactIdentifierCandidates(library: homeLibrary, identifier: identifier)
            candidates += exactIdentifierCandidates(library: systemLibrary, identifier: identifier, systemWide: true)
        }
        if !identifiers.isEmpty {
            candidates += matchingChildren(in: homeLibrary.appendingPathComponent("Group Containers"), identifiers: identifiers, type: .groupContainers, suffixMatch: true)
            candidates += matchingChildren(in: homeLibrary.appendingPathComponent("Application Scripts"), identifiers: identifiers, type: .applicationScripts, suffixMatch: true)
            candidates += matchingFiles(in: homeLibrary.appendingPathComponent("LaunchAgents"), identifiers: identifiers, type: .launchAgent)
            candidates += matchingFiles(in: systemLibrary.appendingPathComponent("LaunchAgents"), identifiers: identifiers, type: .launchAgent)
            candidates += matchingFiles(in: systemLibrary.appendingPathComponent("LaunchDaemons"), identifiers: identifiers, type: .launchDaemon)
            candidates += matchingFiles(in: systemLibrary.appendingPathComponent("PrivilegedHelperTools"), identifiers: identifiers, type: .helperTool)
        }

        let safeName = applicationName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !safeName.isEmpty {
            candidates += namedSupportCandidates(library: homeLibrary, applicationName: safeName)
            candidates += namedSupportCandidates(library: systemLibrary, applicationName: safeName, systemWide: true)
            candidates += matchingFiles(in: homeLibrary.appendingPathComponent("Logs/DiagnosticReports"), identifiers: [safeName], type: .crashReports, prefixMatch: true)
        }

        var leftovers: [LeftoverFile] = []
        var seen = Set<String>()
        for (url, type) in candidates {
            let path = url.standardizedFileURL.path
            guard seen.insert(path).inserted, fileManager.fileExists(atPath: path) else { continue }
            leftovers.append(LeftoverFile(url: url, size: await itemSize(url), type: type))
        }
        return leftovers.sorted { $0.size == $1.size ? $0.url.path < $1.url.path : $0.size > $1.size }
    }

    private func relatedBundleIdentifiers(in bundleURL: URL, primaryIdentifier: String) -> [String] {
        var identifiers = Set<String>()
        if !primaryIdentifier.isEmpty { identifiers.insert(primaryIdentifier) }

        if let info = Bundle(url: bundleURL)?.infoDictionary,
           let helpers = info["SMPrivilegedExecutables"] as? [String: Any] {
            identifiers.formUnion(helpers.keys.filter { !$0.isEmpty })
        }

        let contents = bundleURL.appendingPathComponent("Contents")
        guard let enumerator = fileManager.enumerator(
            at: contents,
            includingPropertiesForKeys: [.isPackageKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else { return identifiers.sorted() }

        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            guard ext == "app" || ext == "xpc" else { continue }
            if let identifier = Bundle(url: url)?.bundleIdentifier, !identifier.isEmpty {
                identifiers.insert(identifier)
            }
            enumerator.skipDescendants()
        }
        return identifiers.sorted()
    }

    private func exactIdentifierCandidates(library: URL, identifier: String, systemWide: Bool = false) -> [(URL, LeftoverType)] {
        var candidates: [(String, LeftoverType)] = [
            ("Preferences/\(identifier).plist", .preferences),
            ("Application Support/\(identifier)", .applicationSupport),
            ("Caches/\(identifier)", .caches),
            ("Logs/\(identifier)", .logs)
        ]
        if !systemWide {
            candidates += [
                ("Containers/\(identifier)", .containers),
                ("Saved Application State/\(identifier).savedState", .savedState),
                ("HTTPStorages/\(identifier)", .httpStorage),
                ("WebKit/\(identifier)", .webKit),
                ("Cookies/\(identifier).binarycookies", .cookies)
            ]
        }
        return candidates.map { (library.appendingPathComponent($0.0), $0.1) }
    }

    private func namedSupportCandidates(library: URL, applicationName: String, systemWide: Bool = false) -> [(URL, LeftoverType)] {
        var candidates: [(String, LeftoverType)] = [
            ("Application Support/\(applicationName)", .sdkSupport),
            ("Caches/\(applicationName)", .caches),
            ("Logs/\(applicationName)", .logs),
            ("Developer/\(applicationName)", .sdkSupport),
            ("SDKs/\(applicationName)", .sdkSupport),
            ("Frameworks/\(applicationName).framework", .sdkSupport),
            ("QuickLook/\(applicationName).qlgenerator", .applicationSupport),
            ("PreferencePanes/\(applicationName).prefPane", .applicationSupport),
            ("Internet Plug-Ins/\(applicationName).plugin", .applicationSupport)
        ]
        if !systemWide {
            candidates += [
                ("Preferences/\(applicationName).plist", .preferences),
                ("Saved Application State/\(applicationName).savedState", .savedState)
            ]
        }
        return candidates.map { (library.appendingPathComponent($0.0), $0.1) }
    }

    private func matchingChildren(in directory: URL, identifiers: [String], type: LeftoverType, suffixMatch: Bool = false) -> [(URL, LeftoverType)] {
        guard let children = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return [] }
        return children.compactMap { url in
            let name = url.lastPathComponent
            let matches = identifiers.contains { name == $0 || (suffixMatch && name.hasSuffix(".\($0)")) }
            return matches ? (url, type) : nil
        }
    }

    private func matchingFiles(in directory: URL, identifiers: [String], type: LeftoverType, prefixMatch: Bool = false) -> [(URL, LeftoverType)] {
        guard let children = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return [] }
        return children.compactMap { url in
            let stem = url.deletingPathExtension().lastPathComponent
            let matches = identifiers.contains { identifier in
                stem == identifier || stem.hasPrefix(identifier + ".") || (prefixMatch && stem.hasPrefix(identifier + "_"))
            }
            return matches ? (url, type) : nil
        }
    }

    private func itemSize(_ url: URL) async -> Int64 {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey])
        if values?.isDirectory == true { return await FileEnumerator.directorySize(url) }
        return Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
    }
}
