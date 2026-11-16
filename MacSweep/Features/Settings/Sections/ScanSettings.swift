import SwiftUI

public struct ScanSettings: View {
    @ObservedObject var viewModel: SettingsViewModel

    public var body: some View {
        VStack(spacing: 12) {
            SettingsCard(
                title: "Large File Detection",
                subtitle: "Choose the minimum file size shown in scan results",
                icon: "doc.badge.arrow.up.fill",
                tint: .orange
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    SettingsInlineRow(
                        title: "Minimum file size",
                        detail: "Smaller files are excluded from Large Files scans",
                        icon: "doc.badge.arrow.up"
                    ) {
                        Text(formattedThreshold)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Stepper(
                        "Adjust minimum size",
                        value: $viewModel.largeFileThresholdMB,
                        in: 10...5000,
                        step: 10
                    )
                    .labelsHidden()
                    .controlSize(.small)

                    HStack(spacing: 8) {
                        ForEach([50, 100, 500, 1000], id: \.self) { size in
                            Button(size == 1000 ? "1 GB" : "\(size) MB") {
                                viewModel.largeFileThresholdMB = size
                            }
                            .buttonStyle(.bordered)
                            .tint(viewModel.largeFileThresholdMB == size ? .orange : .secondary)
                            .controlSize(.small)
                        }
                    }
                }
            }

            HStack(spacing: 9) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("This setting becomes the default threshold for future Large Files scans.")
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
                Spacer()
            }
            .padding(11)
            .background(Color.blue.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var formattedThreshold: String {
        if viewModel.largeFileThresholdMB >= 1000 {
            return String(format: "%.1f GB", Double(viewModel.largeFileThresholdMB) / 1000)
        }
        return "\(viewModel.largeFileThresholdMB) MB"
    }
}
