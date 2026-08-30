import SwiftUI

public struct NotificationSettings: View {
    @ObservedObject var viewModel: SettingsViewModel

    public var body: some View {
        VStack(spacing: 16) {
            SettingsCard(
                title: "Alerts & System Banners",
                subtitle: "Stay informed when background work completes",
                icon: "bell.fill",
                tint: .purple
            ) {
                SettingsToggleRow(
                    title: "Cleanup completion notifications",
                    detail: "Show a system notification after a cleanup finishes",
                    icon: "checkmark.circle",
                    isOn: $viewModel.enableNotifications
                )
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill((viewModel.enableNotifications ? Color.green : Color.gray).opacity(0.13))
                    Image(systemName: viewModel.enableNotifications ? "bell.badge.fill" : "bell.slash.fill")
                        .foregroundColor(viewModel.enableNotifications ? .green : .gray)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.enableNotifications ? "Notifications are enabled" : "Notifications are paused")
                        .font(.system(size: 12, weight: .semibold))
                    Text(viewModel.enableNotifications
                         ? "MacSweep will notify you when cleanup tasks finish."
                         : "Cleanup tasks will finish silently while the app is in the background.")
                        .font(.system(size: 10))
                        .foregroundColor(.msSecondaryLabel)
                }
                Spacer()
            }
            .padding(16)
            .background(Color.msSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
