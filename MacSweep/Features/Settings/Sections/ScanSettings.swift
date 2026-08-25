import SwiftUI

public struct ScanSettings: View {
    @ObservedObject var viewModel: SettingsViewModel

    public var body: some View {
        Form {
            Section(header: Text("Thresholds")) {
                Stepper("Large File Minimum Size: \(viewModel.largeFileThresholdMB) MB", value: $viewModel.largeFileThresholdMB, in: 10...5000, step: 10)
            }
        }
        .padding(16)
    }
}
