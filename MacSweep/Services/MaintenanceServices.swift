import AppKit
import Combine
import Foundation
import ServiceManagement
import UserNotifications
import UniformTypeIdentifiers

public struct CleanupHistoryEntry: Codable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let source: String
    public let processedCount: Int
    public let successCount: Int
    public let failureCount: Int
    public let reclaimedBytes: Int64
    public let duration: TimeInterval

    public init(source: String, result: CleanResult) {
        id = UUID()
        date = Date()
        self.source = source
        processedCount = result.totalItemsProcessed
        successCount = result.successCount
        failureCount = result.failureCount
        reclaimedBytes = result.totalBytesReclaimed
        duration = result.duration
    }
}

@MainActor
public final class CleanupHistoryService: ObservableObject {
    @Published public private(set) var entries: [CleanupHistoryEntry] = []
    private let storageURL: URL

    public init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MacSweep", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        storageURL = base.appendingPathComponent("cleanup-history.json")
        load()
    }

    public func record(source: String, result: CleanResult) {
        entries.insert(CleanupHistoryEntry(source: source, result: result), at: 0)
        entries = Array(entries.prefix(200))
        save()
    }

    public func clear() {
        entries = []
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([CleanupHistoryEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.date > $1.date }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}

@MainActor
public final class ExclusionService: ObservableObject {
    @Published public private(set) var paths: [String] {
        didSet { UserDefaults.standard.set(paths, forKey: "scanExclusionPaths") }
    }

    public init() {
        paths = UserDefaults.standard.stringArray(forKey: "scanExclusionPaths") ?? []
    }

    public func add(_ url: URL) {
        let path = url.standardizedFileURL.path
        guard !paths.contains(path) else { return }
        paths.append(path)
        paths.sort()
    }

    public func remove(_ path: String) { paths.removeAll { $0 == path } }

    public func contains(_ url: URL) -> Bool {
        let candidate = url.standardizedFileURL.path
        return paths.contains { candidate == $0 || candidate.hasPrefix($0 + "/") }
    }

    public func filter(_ items: [CleanupItem]) -> [CleanupItem] {
        items.filter { !contains($0.url) }
    }
}

public enum ScanProfile: String, CaseIterable, Identifiable, Codable, Sendable {
    case quick = "Quick"
    case balanced = "Balanced"
    case developer = "Developer"
    case privacy = "Privacy"
    case custom = "Custom"

    public var id: String { rawValue }
    public var detail: String {
        switch self {
        case .quick: "Caches, logs, and Trash"
        case .balanced: "System and developer cleanup"
        case .developer: "Developer tool caches only"
        case .privacy: "Browser privacy data"
        case .custom: "Your selected system, developer, and rule sources"
        }
    }
}

@MainActor
public final class NotificationService {
    public init() {}

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public func send(title: String, body: String) {
        guard UserDefaults.standard.object(forKey: "enableNotifications") as? Bool ?? true else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

@MainActor
public final class LoginItemService {
    public init() {}

    public var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}

public struct StorageSnapshot: Codable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let totalBytes: Int64
    public let freeBytes: Int64
}

@MainActor
public final class StorageHistoryService: ObservableObject {
    @Published public private(set) var snapshots: [StorageSnapshot] = []
    private let storageURL: URL

    public init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MacSweep", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        storageURL = base.appendingPathComponent("storage-history.json")
        load()
    }

    public func record(_ disk: DiskSpace) {
        let calendar = Calendar.current
        let snapshot = StorageSnapshot(id: UUID(), date: Date(), totalBytes: disk.totalCapacity, freeBytes: disk.availableCapacity)
        snapshots.removeAll { calendar.isDate($0.date, inSameDayAs: snapshot.date) }
        snapshots.append(snapshot)
        snapshots = Array(snapshots.sorted { $0.date < $1.date }.suffix(90))
        save()
    }

    public var freeSpaceChange: Int64? {
        guard let first = snapshots.first, let last = snapshots.last, snapshots.count > 1 else { return nil }
        return last.freeBytes - first.freeBytes
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([StorageSnapshot].self, from: data) else { return }
        snapshots = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}

public struct CustomCleanupRule: Codable, Identifiable, Sendable {
    public var id = UUID()
    public var name: String
    public var path: String
    public var fileExtension: String
    public var minimumAgeDays: Int
    public var isEnabled: Bool
}

@MainActor
public final class CustomRuleService: ObservableObject {
    @Published public var rules: [CustomCleanupRule] {
        didSet { save() }
    }

    public init() {
        if let data = UserDefaults.standard.data(forKey: "customCleanupRules"),
           let decoded = try? JSONDecoder().decode([CustomCleanupRule].self, from: data) {
            rules = decoded
        } else {
            rules = []
        }
    }

    public func add(name: String, path: String, fileExtension: String, minimumAgeDays: Int) {
        rules.append(CustomCleanupRule(name: name, path: path, fileExtension: fileExtension, minimumAgeDays: minimumAgeDays, isEnabled: true))
    }

    public func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) { rules.remove(at: index) }
    }

    public func scan() async -> [CleanupItem] {
        let active = rules.filter(\.isEnabled)
        return await Task.detached {
            var output: [CleanupItem] = []
            let cutoffCalendar = Calendar.current
            for rule in active {
                let root = URL(fileURLWithPath: NSString(string: rule.path).expandingTildeInPath)
                guard root.path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path) else { continue }
                for await metadata in FileEnumerator.enumerate(directory: root, includeHidden: false) {
                    guard !metadata.isDirectory else { continue }
                    if !rule.fileExtension.isEmpty && metadata.url.pathExtension.caseInsensitiveCompare(rule.fileExtension) != .orderedSame { continue }
                    let cutoff = cutoffCalendar.date(byAdding: .day, value: -rule.minimumAgeDays, to: Date()) ?? Date()
                    guard metadata.modificationDate < cutoff else { continue }
                    output.append(CleanupItem(url: metadata.url, size: metadata.size, category: .systemCache, risk: .caution, isDirectory: false, modificationDate: metadata.modificationDate, isSelected: false))
                }
            }
            return output
        }.value
    }

    private func save() {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: "customCleanupRules")
        }
    }
}

@MainActor
public final class DiagnosticReportService {
    public init() {}

    public func export(history: [CleanupHistoryEntry], exclusions: [String], storage: [StorageSnapshot]) throws -> URL {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "MacSweep-Diagnostics.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { throw CocoaError(.userCancelled) }
        let payload: [String: Any] = [
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "macOS": ProcessInfo.processInfo.operatingSystemVersionString,
            "cleanupHistory": history.map { ["date": ISO8601DateFormatter().string(from: $0.date), "source": $0.source, "processed": $0.processedCount, "failed": $0.failureCount, "reclaimedBytes": $0.reclaimedBytes] },
            "exclusionCount": exclusions.count,
            "storageSamples": storage.map { ["date": ISO8601DateFormatter().string(from: $0.date), "freeBytes": $0.freeBytes] }
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: .atomic)
        return url
    }
}

public enum ScanSchedule: String, CaseIterable, Identifiable, Sendable {
    case off = "Off"
    case daily = "Daily"
    case weekly = "Weekly"

    public var id: String { rawValue }
    var interval: TimeInterval? {
        switch self {
        case .off: nil
        case .daily: 86_400
        case .weekly: 604_800
        }
    }
}

@MainActor
public final class AutomationService: ObservableObject {
    @Published public private(set) var isRunning = false
    @Published public private(set) var lastRun: Date?
    private var timer: Timer?
    private let scanEngine: ScanEngine
    private let cleanEngine: CleanEngine
    private let exclusionService: ExclusionService
    private let customRuleService: CustomRuleService
    private let historyService: CleanupHistoryService
    private let notificationService: NotificationService

    public init(
        scanEngine: ScanEngine,
        cleanEngine: CleanEngine,
        exclusionService: ExclusionService,
        customRuleService: CustomRuleService,
        historyService: CleanupHistoryService,
        notificationService: NotificationService
    ) {
        self.scanEngine = scanEngine
        self.cleanEngine = cleanEngine
        self.exclusionService = exclusionService
        self.customRuleService = customRuleService
        self.historyService = historyService
        self.notificationService = notificationService
        configure()
    }

    public func configure() {
        timer?.invalidate()
        timer = nil
        let schedule = ScanSchedule(rawValue: UserDefaults.standard.string(forKey: "scanSchedule") ?? "Off") ?? .off
        guard let interval = schedule.interval else { return }
        let next = UserDefaults.standard.object(forKey: "nextScheduledScan") as? Date ?? Date().addingTimeInterval(interval)
        timer = Timer(fire: next, interval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.runNow() }
        }
        RunLoop.main.add(timer!, forMode: .common)
        UserDefaults.standard.set(next, forKey: "nextScheduledScan")
    }

    public func runNow() async {
        guard !isRunning else { return }
        isRunning = true
        let profile = ScanProfile(rawValue: UserDefaults.standard.string(forKey: "scanProfile") ?? "Balanced") ?? .balanced
        let result: ScanResult
        switch profile {
        case .quick:
            result = await scanEngine.performSmartScan()
        case .privacy:
            let privacy = PrivacyViewModel()
            await privacy.scanPrivacyItems()
            let privacyItems = privacy.items.map {
                CleanupItem(url: $0.path, name: "\($0.browserName) \($0.title)", size: $0.size, category: .browserPrivacy, risk: .caution, isDirectory: (try? $0.path.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false, modificationDate: Date(), isSelected: false)
            }
            result = ScanResult(items: privacyItems, duration: 0, scannedCategories: [.browserPrivacy])
        case .balanced:
            result = await scanEngine.performFullScan()
        case .developer:
            result = await scanEngine.performDeveloperScan()
        case .custom:
            result = UserDefaults.standard.bool(forKey: "customProfileDeveloperSources")
                ? await scanEngine.performFullScan()
                : await scanEngine.performSmartScan()
        }
        var items = exclusionService.filter(result.items)
        if profile == .balanced || (profile == .custom && UserDefaults.standard.bool(forKey: "customProfileRules")) {
            items.append(contentsOf: exclusionService.filter(await customRuleService.scan()))
        }
        if UserDefaults.standard.bool(forKey: "scheduledAutoClean") {
            let safe = items.filter { $0.risk == .safe }
            let cleanResult = await cleanEngine.clean(items: safe)
            historyService.record(source: "Scheduled \(profile.rawValue) Scan", result: cleanResult)
            notificationService.send(title: "Scheduled cleanup finished", body: "Reclaimed \(ByteFormatter.format(cleanResult.totalBytesReclaimed)) from \(cleanResult.successCount) items.")
        } else {
            notificationService.send(title: "Scheduled scan finished", body: "Found \(items.count) items using \(ByteFormatter.format(items.reduce(0) { $0 + $1.size })).")
        }
        lastRun = Date()
        if let interval = (ScanSchedule(rawValue: UserDefaults.standard.string(forKey: "scanSchedule") ?? "Off") ?? .off).interval {
            UserDefaults.standard.set(Date().addingTimeInterval(interval), forKey: "nextScheduledScan")
        }
        isRunning = false
    }
}

@MainActor
public final class ExternalDriveMonitor: ObservableObject {
    @Published public private(set) var lastMountedVolume: URL?
    private var observer: NSObjectProtocol?
    public var onMount: ((URL) -> Void)?

    public init() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let url = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
            Task { @MainActor in
                self?.lastMountedVolume = url
                self?.onMount?(url)
            }
        }
    }

    deinit {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    }
}
