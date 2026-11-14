import AppKit
import Combine
import OSLog
import UserNotifications

@MainActor
public final class StorageAlertService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let alertsEnabledKey = "enableNotifications"
    public static let storageAlertsEnabledKey = "storageAlertsEnabled"
    public static let warningThresholdKey = "storageWarningThreshold"

    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public private(set) var openOptimiseRequest = 0

    private enum AlertLevel: String {
        case warning
        case critical
    }

    private let diskSpaceService: DiskSpaceService
    private let defaults: UserDefaults
    private let notificationCenter = UNUserNotificationCenter.current()
    private var monitorTask: Task<Void, Never>?
    private let lastLevelKey = "storageAlertLastLevel"
    private let lastDateKey = "storageAlertLastDate"

    public init(diskSpaceService: DiskSpaceService, defaults: UserDefaults = .standard) {
        self.diskSpaceService = diskSpaceService
        self.defaults = defaults
        super.init()
        defaults.register(defaults: [
            Self.alertsEnabledKey: true,
            Self.storageAlertsEnabledKey: true,
            Self.warningThresholdKey: 90
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
        guard let diskSpace = try? diskSpaceService.getDiskSpace() else { return }

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

    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "OPEN_OPTIMISE" ||
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
        notificationCenter.setNotificationCategories([
            UNNotificationCategory(
                identifier: "STORAGE_ALERT",
                actions: [action],
                intentIdentifiers: []
            )
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
            content.body = "Storage is \(percentage)% used with \(diskSpace.formattedAvailable) available. Review safe cleanup recommendations in MacSweep."
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
}
