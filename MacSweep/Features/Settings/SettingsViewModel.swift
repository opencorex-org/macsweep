import SwiftUI
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {
    @AppStorage("autoCheckUpdates") public var autoCheckUpdates: Bool = true
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false
    @AppStorage("largeFileThresholdMB") public var largeFileThresholdMB: Int = 100
    @AppStorage("enableNotifications") public var enableNotifications: Bool = true
    @AppStorage("AppSelectedLanguageCode") public var selectedLanguageCode: String = "en"

    /// Convenience wrapper that maps the stored code to/from `AppLanguage`.
    public var selectedLanguage: AppLanguage {
        get { AppLanguage.from(code: selectedLanguageCode) }
        set { selectedLanguageCode = newValue.rawValue }
    }

    public init() {}
}
