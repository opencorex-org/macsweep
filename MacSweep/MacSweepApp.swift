import AppKit
import SwiftUI

@main
struct MacSweepApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var environment = AppEnvironment()
    @StateObject private var localizationStore = LocalizationStore()
    @AppStorage(AppTheme.preferenceKey) private var storedTheme = AppThemePreference.light.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
                .environmentObject(localizationStore)
                .environment(\.locale, localizationStore.locale)
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
            MenuBarView()
                .environmentObject(environment)
            .environmentObject(localizationStore)
            .environment(\.locale, localizationStore.locale)
        } label: {
            StorageMenuLabel(alertService: environment.storageAlertService)
                .environmentObject(localizationStore)
                .environment(\.locale, localizationStore.locale)
        }
        .menuBarExtraStyle(.window)
    }

    private var theme: AppThemePreference {
        AppThemePreference(rawValue: storedTheme) ?? .light
    }

}

private struct StorageMenuLabel: View {
    @ObservedObject var alertService: StorageAlertService

    var body: some View {
        if let diskSpace = alertService.currentDiskSpace {
            Label("\(Int((diskSpace.usedPercentage * 100).rounded()))%", systemImage: "internaldrive")
        } else {
            Label("MacSweep", systemImage: "internaldrive")
        }
    }
}
