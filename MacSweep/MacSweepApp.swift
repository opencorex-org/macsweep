import AppKit
import SwiftUI

@main
struct MacSweepApp: App {
    @Environment(\.scenePhase) private var scenePhase
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
                .task {
                    await environment.storageAlertService.start()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { await environment.storageAlertService.checkStorage() }
                }
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

        MenuBarExtra {
            StorageMenuView(environment: environment)
        } label: {
            Label("MacSweep", systemImage: "internaldrive")
        }
        .menuBarExtraStyle(.menu)
    }

    private var theme: AppThemePreference {
        AppThemePreference(rawValue: storedTheme) ?? .light
    }
}

private struct StorageMenuView: View {
    @ObservedObject var environment: AppEnvironment
    @State private var diskSpace: DiskSpace?

    var body: some View {
        Group {
            if let diskSpace {
                Text("Storage \(Int((diskSpace.usedPercentage * 100).rounded()))% used")
                Text("\(diskSpace.formattedAvailable) available")
            } else {
                Text("Storage unavailable")
            }
            Divider()
            Button("Check Storage Now") {
                diskSpace = try? environment.diskSpaceService.getDiskSpace()
                Task { await environment.storageAlertService.checkStorage(force: true) }
            }
            Button("Open MacSweep") { NSApplication.shared.activate(ignoringOtherApps: true) }
            Divider()
            Button("Quit MacSweep") { NSApplication.shared.terminate(nil) }
        }
        .onAppear { diskSpace = try? environment.diskSpaceService.getDiskSpace() }
    }
}
