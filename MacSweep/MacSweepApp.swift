import SwiftUI

@main
struct MacSweepApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
