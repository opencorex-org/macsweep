import SwiftUI
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false
    @AppStorage("largeFileThresholdMB") public var largeFileThresholdMB: Int = 100
    @AppStorage("enableNotifications") public var enableNotifications: Bool = true
    @AppStorage(StorageAlertService.storageAlertsEnabledKey) public var storageAlertsEnabled: Bool = true
    @AppStorage(StorageAlertService.warningThresholdKey) public var storageWarningThreshold: Int = 90
    @AppStorage("AppSelectedLanguageCode") public var selectedLanguageCode: String = "en"
    @AppStorage(AppTheme.preferenceKey) public var selectedThemeRawValue: String = AppThemePreference.light.rawValue

    /// Convenience wrapper that maps the stored code to/from `AppLanguage`.
    public var selectedLanguage: AppLanguage {
        get { AppLanguage.from(code: selectedLanguageCode) }
        set { selectedLanguageCode = newValue.rawValue }
    }

    /// Typed access to the persisted application appearance.
    public var selectedTheme: AppThemePreference {
        get { AppThemePreference(rawValue: selectedThemeRawValue) ?? .light }
        set { selectedThemeRawValue = newValue.rawValue }
    }

    public init() {}
}
