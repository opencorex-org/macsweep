import SwiftUI

public struct PrivacySettings: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var permissionManager: PermissionManager

    public var body: some View {
        VStack(spacing: 12) {
            SettingsCard(
                title: "Full Disk Access",
                subtitle: "Required for complete scans and safe removal",
                icon: "externaldrive.badge.checkmark",
                tint: permissionManager.hasFullDiskAccess ? .green : .orange
            ) {
                VStack(spacing: 11) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(statusColor.opacity(0.13))
                            Image(systemName: permissionManager.hasFullDiskAccess ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                .font(.system(size: 18))
                                .foregroundColor(statusColor)
                        }
                        .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(permissionManager.hasFullDiskAccess ? "Access Granted" : "Access Not Granted")
                                .font(.system(size: 13, weight: .bold))
                            Text(permissionManager.hasFullDiskAccess
                                 ? "MacSweep can inspect protected folders for complete results."
                                 : "Some caches, app containers, logs, and files will be inaccessible.")
                                .font(.system(size: 10))
                                .foregroundColor(.msSecondaryLabel)
                        }
                        Spacer()
                    }

                    HStack(spacing: 10) {
                        if !permissionManager.hasFullDiskAccess {
                            Button("Open Privacy Settings") {
                                permissionManager.requestFullDiskAccess()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Button("Check Again") {
                            permissionManager.refreshPermissions()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }
                    .controlSize(.small)
                }
            }

            SettingsCard(
                title: "Privacy by Design",
                subtitle: "Your files stay on this Mac",
                icon: "lock.shield.fill",
                tint: .green
            ) {
                VStack(spacing: 10) {
                    privacyRow(
                        icon: "internaldrive.fill",
                        title: "Local processing",
                        detail: "File scanning and cleanup happen entirely on your Mac."
                    )
                    Divider().padding(.leading, 33)
                    privacyRow(
                        icon: "trash.slash.fill",
                        title: "Cleanup behavior",
                        detail: "Smart Scan, Full Scan, and Developer Cleaner permanently delete only the items you approve. Large Files and App Uninstaller continue to move files to Trash."
                    )
                    Divider().padding(.leading, 33)
                    privacyRow(
                        icon: "eye.slash.fill",
                        title: "No file uploads",
                        detail: "MacSweep does not upload the contents of scanned files."
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var statusColor: Color {
        permissionManager.hasFullDiskAccess ? .green : .orange
    }

    private func privacyRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 12, weight: .medium))
                Text(LocalizedStringKey(detail))
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
            }
            Spacer()
        }
    }
}
