import SwiftUI
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false
    @AppStorage("largeFileThresholdMB") public var largeFileThresholdMB: Int = 100
    @AppStorage("enableNotifications") public var enableNotifications: Bool = true
    @AppStorage(StorageAlertService.storageAlertsEnabledKey) public var storageAlertsEnabled: Bool = true
    @AppStorage(StorageAlertService.warningThresholdKey) public var storageWarningThreshold: Int = 90
    @AppStorage(StorageAlertService.externalAlertsEnabledKey) public var externalStorageAlertsEnabled: Bool = true
    @AppStorage(StorageAlertService.scheduledScanKey) public var scheduledScanFrequency: String = "weekly"
    @AppStorage(AppTheme.preferenceKey) public var selectedThemeRawValue: String = AppThemePreference.light.rawValue
    @AppStorage("AppSelectedLanguageCode") public var selectedLanguageCode: String = "en"
    @AppStorage("scanSchedule") public var scanScheduleRawValue: String = ScanSchedule.off.rawValue
    @AppStorage("scanProfile") public var scanProfileRawValue: String = ScanProfile.balanced.rawValue
    @AppStorage("scheduledAutoClean") public var scheduledAutoClean: Bool = false
    @AppStorage("externalDriveAutoScan") public var externalDriveAutoScan: Bool = false
    @AppStorage("customProfileDeveloperSources") public var customProfileDeveloperSources: Bool = true
    @AppStorage("customProfileRules") public var customProfileRules: Bool = true

    public var scanSchedule: ScanSchedule {
        get { ScanSchedule(rawValue: scanScheduleRawValue) ?? .off }
        set { scanScheduleRawValue = newValue.rawValue }
    }

    public var scanProfile: ScanProfile {
        get { ScanProfile(rawValue: scanProfileRawValue) ?? .balanced }
        set { scanProfileRawValue = newValue.rawValue }
    }

    /// Typed access to the persisted application appearance.
    public var selectedTheme: AppThemePreference {
        get { AppThemePreference(rawValue: selectedThemeRawValue) ?? .light }
        set { selectedThemeRawValue = newValue.rawValue }
    }

    public init() {}
}
