import SwiftUI

public struct ContentView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var coordinator = NavigationCoordinator()

    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidebarView(selection: $coordinator.selectedItem)
        } detail: {
            if let selectedItem = coordinator.selectedItem {
                switch selectedItem {
                case .dashboard:
                    DashboardView(environment: environment)
                case .smartScan:
                    SmartScanView(environment: environment)
                case .storageAnalyzer:
                    StorageAnalyzerView()
                case .duplicates:
                    DuplicatesView()
                case .largeFiles:
                    LargeFilesView(environment: environment)
                case .developerCleaner:
                    DeveloperCleanerView(environment: environment)
                case .startupItems:
                    StartupItemsView()
                case .uninstaller:
                    UninstallerView(environment: environment)
                case .privacy:
                    PrivacyView()
                case .settings:
                    SettingsView()
                }
            } else {
                DashboardView(environment: environment)
            }
        }
        .environmentObject(coordinator)
        .sheet(isPresented: $coordinator.showOnboarding) {
            OnboardingView {
                coordinator.showOnboarding = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment())
}
