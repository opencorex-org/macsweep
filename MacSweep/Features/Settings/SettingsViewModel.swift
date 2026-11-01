import SwiftUI
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false
    @AppStorage("largeFileThresholdMB") public var largeFileThresholdMB: Int = 100
    @AppStorage("enableNotifications") public var enableNotifications: Bool = true
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

    /// Convenience wrapper that maps the stored code to/from `AppLanguage`.
    public var selectedLanguage: AppLanguage {
        get { AppLanguage.from(code: selectedLanguageCode) }
        set { selectedLanguageCode = newValue.rawValue }
    }

    public init() {}
}
