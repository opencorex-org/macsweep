import SwiftUI

@main
struct MacSweepApp: App {
    @StateObject private var environment = AppEnvironment()

    init() {
        // Apply the user's saved language preference before any window is shown.
        LanguageManager.shared.applyOnLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
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

        MenuBarExtra("MacSweep", systemImage: "sparkles") {
            MenuBarView()
                .environmentObject(environment)
        }
        .menuBarExtraStyle(.window)
    }
}
