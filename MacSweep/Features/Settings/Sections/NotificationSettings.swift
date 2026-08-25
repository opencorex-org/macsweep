import SwiftUI

public struct NotificationSettings: View {
    @ObservedObject var viewModel: SettingsViewModel

    public var body: some View {
        Form {
            Section(header: Text("Alerts & System Banners")) {
                Toggle("Enable cleanup completion notifications", isOn: $viewModel.enableNotifications)
            }
        }
        .padding(16)
    }
}
