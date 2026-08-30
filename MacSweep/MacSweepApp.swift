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
    }
}
