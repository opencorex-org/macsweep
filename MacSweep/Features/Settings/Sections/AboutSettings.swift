import SwiftUI
import AppKit

public struct AboutSettings: View {
    public var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 14) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .accessibilityHidden(true)

                Text("MacSweep")
                    .font(.system(size: 24, weight: .bold))

                Text(versionText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.msSecondaryLabel)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Capsule())

                Text("A focused macOS utility for understanding storage, removing clutter, and keeping developer workspaces tidy.")
                    .font(.system(size: 12))
                    .foregroundColor(.msSecondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 430)
            }
            .padding(.vertical, 12)

            SettingsCard(
                title: "Application",
                subtitle: "Build and compatibility information",
                icon: "desktopcomputer",
                tint: .blue
            ) {
                VStack(spacing: 12) {
                    infoRow(title: "Version", value: shortVersion)
                    Divider()
                    infoRow(title: "Build", value: buildNumber)
                    Divider()
                    infoRow(title: "Minimum macOS", value: "14.0 Sonoma")
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private var versionText: String { "Version \(shortVersion) (\(buildNumber))" }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.msSecondaryLabel)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.msLabel)
        }
    }
}
