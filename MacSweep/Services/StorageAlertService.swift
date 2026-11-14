import AppKit
import Combine
import OSLog
import UserNotifications

@MainActor
public final class StorageAlertService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let alertsEnabledKey = "enableNotifications"
    public static let storageAlertsEnabledKey = "storageAlertsEnabled"
    public static let warningThresholdKey = "storageWarningThreshold"
    public static let externalAlertsEnabledKey = "externalStorageAlertsEnabled"
    public static let scheduledScanKey = "scheduledScanFrequency"
    public static let snoozedUntilKey = "storageAlertsSnoozedUntil"

    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public private(set) var openOptimiseRequest = 0
    @Published public private(set) var openSmartScanRequest = 0

    private enum AlertLevel: String {
        case warning
        case critical
    }

    private let diskSpaceService: DiskSpaceService
    private let volumeService: VolumeService
    private let defaults: UserDefaults
    private let notificationCenter = UNUserNotificationCenter.current()
    private var monitorTask: Task<Void, Never>?
    private let lastLevelKey = "storageAlertLastLevel"
    private let lastDateKey = "storageAlertLastDate"
    private let lastScanReminderKey = "scheduledScanLastReminder"
    private let historyKey = "storageUsageHistory"

    private struct UsageSample: Codable { let date: Date; let usedFraction: Double }

    public init(diskSpaceService: DiskSpaceService, volumeService: VolumeService, defaults: UserDefaults = .standard) {
        self.diskSpaceService = diskSpaceService
        self.volumeService = volumeService
        self.defaults = defaults
        super.init()
        defaults.register(defaults: [
            Self.alertsEnabledKey: true,
            Self.storageAlertsEnabledKey: true,
            Self.warningThresholdKey: 90,
            Self.externalAlertsEnabledKey: true,
            Self.scheduledScanKey: "weekly"
        ])
        notificationCenter.delegate = self
        registerNotificationCategory()
    }

    deinit {
        monitorTask?.cancel()
    }

    public func start() async {
        guard monitorTask == nil else { return }
        await refreshAuthorizationStatus()
        if authorizationStatus == .notDetermined, alertsAreEnabled {
            await requestAuthorization()
        }
        await checkStorage()

        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1_800))
                guard !Task.isCancelled else { return }
                await self?.checkStorage()
            }
        }
    }

    public func settingsDidChange() async {
        await refreshAuthorizationStatus()
        if authorizationStatus == .notDetermined, alertsAreEnabled {
            await requestAuthorization()
        }
        await checkStorage(force: true)
    }

    public func requestAuthorization() async {
        do {
            _ = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
        } catch {
            Logger.app.error("Notification authorization failed: \(error.localizedDescription)")
        }
        await refreshAuthorizationStatus()
    }

    public func checkStorage(force: Bool = false) async {
        guard alertsAreEnabled, authorizationStatus == .authorized else { return }
        if let snoozedUntil = defaults.object(forKey: Self.snoozedUntilKey) as? Date, snoozedUntil > Date(), !force { return }
        guard let diskSpace = try? diskSpaceService.getDiskSpace() else { return }

        recordUsage(diskSpace.usedPercentage)
        await sendScheduledScanReminderIfNeeded()
        if defaults.bool(forKey: Self.externalAlertsEnabledKey) {
            await checkExternalVolumes(force: force)
        }

        let usedFraction = diskSpace.usedPercentage
        let warningThreshold = min(max(defaults.integer(forKey: Self.warningThresholdKey), 80), 98)
        let level: AlertLevel?
        if usedFraction >= 0.99 {
            level = .critical
        } else if usedFraction >= Double(warningThreshold) / 100 {
            level = .warning
        } else {
            level = nil
        }

        guard let level else {
            if usedFraction < Double(warningThreshold - 2) / 100 {
                resetCooldown()
            }
            return
        }
        guard force || shouldNotify(level: level) else { return }
        await sendNotification(level: level, diskSpace: diskSpace)
        defaults.set(level.rawValue, forKey: lastLevelKey)
        defaults.set(Date(), forKey: lastDateKey)
    }

    public func openNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") else { return }
        NSWorkspace.shared.open(url)
    }

    public func snoozeAlerts(for interval: TimeInterval = 86_400) {
        defaults.set(Date().addingTimeInterval(interval), forKey: Self.snoozedUntilKey)
    }

    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "OPEN_SMART_SCAN" ||
            (response.actionIdentifier == UNNotificationDefaultActionIdentifier && response.notification.request.content.categoryIdentifier == "SCAN_REMINDER") {
            Task { @MainActor [weak self] in
                self?.openSmartScanRequest += 1
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        } else if response.actionIdentifier == "SNOOZE_ALERTS" {
            Task { @MainActor [weak self] in self?.snoozeAlerts() }
        } else if response.actionIdentifier == "OPEN_OPTIMISE" ||
            response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            Task { @MainActor [weak self] in
                self?.openOptimiseRequest += 1
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
        completionHandler()
    }

    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private var alertsAreEnabled: Bool {
        defaults.bool(forKey: Self.alertsEnabledKey) &&
            defaults.bool(forKey: Self.storageAlertsEnabledKey)
    }

    private func refreshAuthorizationStatus() async {
        authorizationStatus = await notificationCenter.notificationSettings().authorizationStatus
    }

    private func registerNotificationCategory() {
        let action = UNNotificationAction(
            identifier: "OPEN_OPTIMISE",
            title: "Open Optimise",
            options: [.foreground]
        )
        let snooze = UNNotificationAction(identifier: "SNOOZE_ALERTS", title: "Snooze 24 Hours")
        let smartScan = UNNotificationAction(identifier: "OPEN_SMART_SCAN", title: "Open Smart Scan", options: [.foreground])
        notificationCenter.setNotificationCategories([
            UNNotificationCategory(
                identifier: "STORAGE_ALERT",
                actions: [action, snooze],
                intentIdentifiers: []
            ),
            UNNotificationCategory(identifier: "SCAN_REMINDER", actions: [smartScan], intentIdentifiers: [])
        ])
    }

    private func shouldNotify(level: AlertLevel) -> Bool {
        let lastLevel = defaults.string(forKey: lastLevelKey)
        let lastDate = defaults.object(forKey: lastDateKey) as? Date ?? .distantPast
        if lastLevel != level.rawValue { return true }
        let cooldown: TimeInterval = level == .critical ? 6 * 60 * 60 : 24 * 60 * 60
        return Date().timeIntervalSince(lastDate) >= cooldown
    }

    private func sendNotification(level: AlertLevel, diskSpace: DiskSpace) async {
        let percentage = Int((diskSpace.usedPercentage * 100).rounded())
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "STORAGE_ALERT"
        content.sound = .default

        switch level {
        case .warning:
            content.title = "Mac storage is getting full"
            content.body = "Storage is \(percentage)% used with \(diskSpace.formattedAvailable) available.\(trendMessage) Review safe cleanup recommendations in MacSweep."
        case .critical:
            content.title = "Critical: Mac storage is 99% full"
            content.body = "Only \(diskSpace.formattedAvailable) remains. Open MacSweep and clean storage now to keep macOS responsive."
        }

        let identifier = "MacSweep.storage.\(level.rawValue)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        do {
            try await notificationCenter.add(UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: nil
            ))
        } catch {
            Logger.app.error("Storage notification failed: \(error.localizedDescription)")
        }
    }

    private func resetCooldown() {
        defaults.removeObject(forKey: lastLevelKey)
        defaults.removeObject(forKey: lastDateKey)
    }

    private var trendMessage: String {
        guard let data = defaults.data(forKey: historyKey),
              let samples = try? JSONDecoder().decode([UsageSample].self, from: data),
              let first = samples.first, let last = samples.last, samples.count >= 2 else { return "" }
        let days = last.date.timeIntervalSince(first.date) / 86_400
        let growth = last.usedFraction - first.usedFraction
        guard days >= 1, growth > 0.005 else { return "" }
        let daysToFull = Int(((1 - last.usedFraction) / (growth / days)).rounded(.up))
        guard daysToFull > 0, daysToFull < 90 else { return "" }
        return " At the recent rate it may fill in about \(daysToFull) day\(daysToFull == 1 ? "" : "s")."
    }

    private func recordUsage(_ usedFraction: Double) {
        let decoder = JSONDecoder()
        var samples = defaults.data(forKey: historyKey).flatMap { try? decoder.decode([UsageSample].self, from: $0) } ?? []
        if let last = samples.last, Date().timeIntervalSince(last.date) < 21_600 { return }
        samples.append(UsageSample(date: Date(), usedFraction: usedFraction))
        samples = samples.filter { Date().timeIntervalSince($0.date) <= 30 * 86_400 }
        if let data = try? JSONEncoder().encode(samples) { defaults.set(data, forKey: historyKey) }
    }

    private func checkExternalVolumes(force: Bool) async {
        let warning = Double(min(max(defaults.integer(forKey: Self.warningThresholdKey), 80), 98)) / 100
        for volume in await volumeService.discoverVolumes() where volume.isExternal && volume.usedPercentage >= warning {
            let identifier = "MacSweep.storage.external.\(volume.volumeUUID.isEmpty ? volume.name : volume.volumeUUID)"
            let cooldownKey = identifier + ".lastDate"
            let lastDate = defaults.object(forKey: cooldownKey) as? Date ?? .distantPast
            if !force, Date().timeIntervalSince(lastDate) < 24 * 60 * 60 { continue }
            let content = UNMutableNotificationContent()
            content.categoryIdentifier = "STORAGE_ALERT"
            content.sound = .default
            content.title = "\(volume.name) is nearly full"
            content.body = "\(Int((volume.usedPercentage * 100).rounded()))% used with \(volume.formattedAvailable) available."
            try? await notificationCenter.add(.init(identifier: identifier, content: content, trigger: nil))
            defaults.set(Date(), forKey: cooldownKey)
        }
    }

    private func sendScheduledScanReminderIfNeeded() async {
        let frequency = defaults.string(forKey: Self.scheduledScanKey) ?? "weekly"
        guard frequency != "off" else { return }
        let interval: TimeInterval = frequency == "daily" ? 86_400 : 7 * 86_400
        guard let last = defaults.object(forKey: lastScanReminderKey) as? Date else {
            defaults.set(Date(), forKey: lastScanReminderKey)
            return
        }
        guard Date().timeIntervalSince(last) >= interval else { return }
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "SCAN_REMINDER"
        content.title = "Time for a MacSweep Smart Scan"
        content.body = "Review new cleanup recommendations. MacSweep never deletes items on a schedule."
        try? await notificationCenter.add(.init(identifier: "MacSweep.scan.reminder", content: content, trigger: nil))
        defaults.set(Date(), forKey: lastScanReminderKey)
    }
}
