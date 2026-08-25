import SwiftUI

public struct PrivacySettings: View {
    @ObservedObject var viewModel: SettingsViewModel

    public var body: some View {
        Form {
            Section(header: Text("Permissions & Disk Access")) {
                Text("Full Disk Access is required for MacSweep to scan and clean system-wide caches and logs.")
                    .font(.system(size: 12))
                    .foregroundColor(.msSecondaryLabel)

                Button("Open Privacy & Security Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .padding(16)
    }
}
