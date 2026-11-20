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
                VStack(alignment: .leading, spacing: 14) {
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

                    HStack(spacing: 10) {
                        thresholdButton(icon: "minus", delta: -10)

                        Slider(
                            value: Binding(
                                get: { Double(viewModel.largeFileThresholdMB) },
                                set: { viewModel.largeFileThresholdMB = Int(($0 / 10).rounded()) * 10 }
                            ),
                            in: 10...5000
                        )
                        .tint(.orange)
                        .focusEffectDisabled()
                        .accessibilityLabel("Minimum file size")
                        .accessibilityValue(formattedThreshold)

                        thresholdButton(icon: "plus", delta: 10)
                    }

                    HStack(spacing: 8) {
                        ForEach([50, 100, 500, 1000], id: \.self) { size in
                            Button(size == 1000 ? "1 GB" : "\(size) MB") {
                                viewModel.largeFileThresholdMB = size
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(viewModel.largeFileThresholdMB == size ? .orange : .msSecondaryLabel)
                            .padding(.horizontal, 11)
                            .frame(height: 26)
                            .background(
                                viewModel.largeFileThresholdMB == size
                                    ? Color.orange.opacity(0.12)
                                    : Color.primary.opacity(0.045),
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(
                                        viewModel.largeFileThresholdMB == size
                                            ? Color.orange.opacity(0.28)
                                            : Color.msSeparator.opacity(0.35),
                                        lineWidth: 0.5
                                    )
                            }
                        }
                        Spacer()
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

    private func thresholdButton(icon: String, delta: Int) -> some View {
        Button {
            viewModel.largeFileThresholdMB = min(5000, max(10, viewModel.largeFileThresholdMB + delta))
        } label: {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 26, height: 26)
                .background(Color.primary.opacity(0.055), in: Circle())
                .overlay {
                    Circle().stroke(Color.msSeparator.opacity(0.5), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .disabled(delta < 0 ? viewModel.largeFileThresholdMB <= 10 : viewModel.largeFileThresholdMB >= 5000)
        .accessibilityLabel(delta < 0 ? "Decrease minimum file size" : "Increase minimum file size")
    }
}
