import SwiftUI
import Combine

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
                case .optimise:
                    OptimiseView(environment: environment)
                case .activityLog:
                    ActivityLogView(store: environment.activityLogStore)
                case .insights:
                    InsightsView(environment: environment)
                case .fullScan:
                    FullScanView(environment: environment)
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
                    PrivacyView(environment: environment)
                case .appMover:
                    AppMoverView(environment: environment)
                case .storageManager:
                    StorageManagerView(environment: environment)
                case .settings:
                    SettingsView()
                }
            } else {
                DashboardView(environment: environment)
            }
        }
        .environmentObject(coordinator)
        .onReceive(environment.storageAlertService.$openOptimiseRequest.dropFirst()) { _ in
            coordinator.navigate(to: .optimise)
        }
        .onReceive(environment.storageAlertService.$openSmartScanRequest.dropFirst()) { _ in
            coordinator.navigate(to: .smartScan)
        }
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
