import SwiftUI
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {
    @AppStorage("autoCheckUpdates") public var autoCheckUpdates: Bool = true
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false
    @AppStorage("largeFileThresholdMB") public var largeFileThresholdMB: Int = 100
    @AppStorage("enableNotifications") public var enableNotifications: Bool = true

    public init() {}
}
