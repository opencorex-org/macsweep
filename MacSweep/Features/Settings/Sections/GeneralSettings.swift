import SwiftUI

public struct GeneralSettings: View {
    @ObservedObject var viewModel: SettingsViewModel

    public var body: some View {
        Form {
            Section(header: Text("Startup & Updates")) {
                Toggle("Launch MacSweep at login", isOn: $viewModel.launchAtLogin)
                Toggle("Automatically check for updates", isOn: $viewModel.autoCheckUpdates)
            }
        }
        .padding(16)
    }
}
