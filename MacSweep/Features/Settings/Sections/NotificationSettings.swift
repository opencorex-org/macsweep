import SwiftUI
import UserNotifications

public struct NotificationSettings: View {
    @EnvironmentObject private var environment: AppEnvironment
    @ObservedObject var viewModel: SettingsViewModel

    public var body: some View {
        VStack(spacing: 12) {
            SettingsCard(
                title: "Alerts & System Banners",
                subtitle: "Stay informed when background work completes",
                icon: "bell.fill",
                tint: .purple
            ) {
                VStack(spacing: 10) {
                    SettingsToggleRow(
                        title: "Allow system notifications",
                        detail: "Show important MacSweep alerts and completion banners",
                        icon: "bell.badge",
                        isOn: notificationBinding
                    )

                    Divider().padding(.leading, 33)

                    SettingsToggleRow(
                        title: "Storage capacity alerts",
                        detail: "Warn before storage is full and send a critical alert at 99%",
                        icon: "internaldrive.fill",
                        isOn: storageAlertBinding
                    )
                    .disabled(!viewModel.enableNotifications)

                    Divider().padding(.leading, 33)

                    SettingsInlineRow(
                        title: "Early warning threshold",
                        detail: "The critical alert always triggers at 99% used",
                        icon: "gauge.with.dots.needle.67percent"
                    ) {
                        SettingsMenu(value: "\(viewModel.storageWarningThreshold)% used", width: 122) {
                            ForEach([85, 90, 95, 98], id: \.self) { threshold in
                                Button {
                                    viewModel.storageWarningThreshold = threshold
                                    Task { await environment.storageAlertService.settingsDidChange() }
                                } label: {
                                    if viewModel.storageWarningThreshold == threshold {
                                        Label("\(threshold)% used", systemImage: "checkmark")
                                    } else {
                                        Text("\(threshold)% used")
                                    }
                                }
                            }
                        }
                        .accessibilityLabel("Early warning threshold")
                    }
                    .disabled(!viewModel.enableNotifications || !viewModel.storageAlertsEnabled)

                    Divider().padding(.leading, 33)

                    SettingsToggleRow(
                        title: "External drive alerts",
                        detail: "Warn when a connected drive reaches the same capacity threshold",
                        icon: "externaldrive.badge.exclamationmark",
                        isOn: $viewModel.externalStorageAlertsEnabled
                    )
                    .disabled(!viewModel.enableNotifications)
                }
            }

            SettingsCard(
                title: "Smart Scan Schedule",
                subtitle: "Reminders only—files are never deleted automatically",
                icon: "calendar.badge.clock",
                tint: .blue
            ) {
                SettingsInlineRow(
                    title: "Scan reminder",
                    detail: "Open MacSweep to review each recommendation",
                    icon: "calendar.badge.clock"
                ) {
                    SettingsMenu(value: reminderTitle, width: 112) {
                        reminderOption("Off", value: "off")
                        reminderOption("Daily", value: "daily")
                        reminderOption("Weekly", value: "weekly")
                    }
                    .accessibilityLabel("Scan reminder")
                }
            }

            HStack {
                Button("Snooze storage alerts for 24 hours", systemImage: "bell.slash") {
                    environment.storageAlertService.snoozeAlerts()
                }
                .buttonStyle(.bordered)
                Spacer()
                Text("Scheduled reminders continue after the snooze ends.")
                    .font(.system(size: 10)).foregroundColor(.msSecondaryLabel)
            }
            .controlSize(.small)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.13))
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.system(size: 12, weight: .semibold))
                    Text(statusDetail)
                        .font(.system(size: 10))
                        .foregroundColor(.msSecondaryLabel)
                }
                Spacer()

                if environment.storageAlertService.authorizationStatus == .denied {
                    Button("Open Notification Settings") {
                        environment.storageAlertService.openNotificationSettings()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(13)
            .background(Color.msSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var notificationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.enableNotifications },
            set: { enabled in
                viewModel.enableNotifications = enabled
                Task { await environment.storageAlertService.settingsDidChange() }
            }
        )
    }

    private var storageAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.storageAlertsEnabled },
            set: { enabled in
                viewModel.storageAlertsEnabled = enabled
                Task { await environment.storageAlertService.settingsDidChange() }
            }
        )
    }

    private var statusColor: Color {
        if environment.storageAlertService.authorizationStatus == .denied { return .orange }
        return viewModel.enableNotifications ? .green : .gray
    }

    private var statusIcon: String {
        if environment.storageAlertService.authorizationStatus == .denied { return "exclamationmark.bell.fill" }
        return viewModel.enableNotifications ? "bell.badge.fill" : "bell.slash.fill"
    }

    private var statusTitle: String {
        if environment.storageAlertService.authorizationStatus == .denied {
            return "Notifications are blocked by macOS"
        }
        return viewModel.enableNotifications ? "Storage monitoring is active" : "Notifications are paused"
    }

    private var statusDetail: String {
        if environment.storageAlertService.authorizationStatus == .denied {
            return "Allow notifications in System Settings to receive storage alerts."
        }
        if viewModel.enableNotifications && viewModel.storageAlertsEnabled {
            return "Warning at \(viewModel.storageWarningThreshold)% and critical alert at 99% used."
        }
        return "MacSweep will not show storage capacity alerts."
    }

    private var reminderTitle: String {
        switch viewModel.scheduledScanFrequency {
        case "daily": "Daily"
        case "weekly": "Weekly"
        default: "Off"
        }
    }

    @ViewBuilder
    private func reminderOption(_ title: String, value: String) -> some View {
        Button {
            viewModel.scheduledScanFrequency = value
        } label: {
            if viewModel.scheduledScanFrequency == value {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }
}
