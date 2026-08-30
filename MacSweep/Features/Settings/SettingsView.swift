import SwiftUI

public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    public init() {}

    public var body: some View {
        TabView {
            GeneralSettings(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            ScanSettings(viewModel: viewModel)
                .tabItem {
                    Label("Scanning", systemImage: "slider.horizontal.3")
                }

            NotificationSettings(viewModel: viewModel)
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            PrivacySettings(viewModel: viewModel)
                .tabItem {
                    Label("Privacy", systemImage: "lock")
                }

            AboutSettings()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 520, height: 420)
        .padding()
    }
}
