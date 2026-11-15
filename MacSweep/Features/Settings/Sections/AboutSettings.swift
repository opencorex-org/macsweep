import SwiftUI
import AppKit

public struct AboutSettings: View {
    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text("MacSweep")
                            .font(.system(size: 21, weight: .bold))
                        Text(versionText)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.msSecondaryLabel)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Capsule())
                    }

                    Text("A focused macOS utility for understanding storage, removing clutter, and keeping developer workspaces tidy.")
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)

            SettingsCard(
                title: "Application",
                subtitle: "Version and compatibility information",
                icon: "desktopcomputer",
                tint: .blue
            ) {
                VStack(spacing: 9) {
                    infoRow(title: "Version", value: shortVersion)
                    Divider()
                    infoRow(title: "Minimum macOS", value: "14.0 Sonoma")
                }
            }

            SettingsCard(
                title: "Support MacSweep",
                subtitle: "Help keep MacSweep independent and improving",
                icon: "heart.fill",
                tint: .pink
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("MacSweep is free and independently developed. If it saves you time or storage space, you can support continued development through GitHub Sponsors.")
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Link(destination: AppConstants.App.sponsorURL) {
                            Label("Sponsor on GitHub", systemImage: "heart.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)

                        Link(destination: AppConstants.App.repositoryURL) {
                            Label("View Source", systemImage: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .controlSize(.small)

                    Label("Sponsorship is completely optional and does not unlock or restrict features.", systemImage: "checkmark.shield.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.msSecondaryLabel)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var versionText: String { "Version \(shortVersion)" }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(.system(size: 11))
                .foregroundColor(.msSecondaryLabel)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.msLabel)
        }
    }
}
