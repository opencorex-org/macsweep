import SwiftUI

@main
struct MacSweepApp: App {
    @StateObject private var environment = AppEnvironment()
    @AppStorage(AppTheme.preferenceKey) private var storedTheme = AppThemePreference.light.rawValue

    init() {
        // Apply the user's saved language preference before any window is shown.
        LanguageManager.shared.applyOnLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
                .preferredColorScheme(theme.colorScheme)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    environment.updateService.checkForUpdates()
                }
                .disabled(!environment.updateService.isConfigured)
            }
        }
    }

    private var theme: AppThemePreference {
        AppThemePreference(rawValue: storedTheme) ?? .light
    }
}
