import SwiftUI

private enum SettingsPane: String, CaseIterable, Identifiable {
    case general, scanning, notifications, privacy, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .scanning: "Scanning"
        case .notifications: "Notifications"
        case .privacy: "Privacy & Access"
        case .about: "About"
        }
    }

    var subtitle: String {
        switch self {
        case .general: "Startup, updates, and language"
        case .scanning: "File detection preferences"
        case .notifications: "Cleanup alerts and banners"
        case .privacy: "Permissions and data handling"
        case .about: "Version and application details"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape.fill"
        case .scanning: "magnifyingglass"
        case .notifications: "bell.badge.fill"
        case .privacy: "hand.raised.fill"
        case .about: "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .general: .blue
        case .scanning: .orange
        case .notifications: .purple
        case .privacy: .green
        case .about: .msAccent
        }
    }
}

public struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedPane: SettingsPane = .general

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            settingsSidebar
            Divider()
            settingsDetail
        }
        .background(Color.msBackground)
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.msLabel)
                Text("Make MacSweep work your way")
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 14)

            VStack(spacing: 5) {
                ForEach(SettingsPane.allCases) { pane in
                    Button {
                        withAnimation(.easeInOut(duration: AppTheme.animationDuration)) {
                            selectedPane = pane
                        }
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(pane.tint.opacity(selectedPane == pane ? 0.18 : 0.10))
                                Image(systemName: pane.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(pane.tint)
                            }
                            .frame(width: 28, height: 28)

                            Text(pane.title)
                                .font(.system(size: 12, weight: selectedPane == pane ? .semibold : .medium))
                                .foregroundColor(.msLabel)
                            Spacer()
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selectedPane == pane ? Color.msAccent.opacity(0.11) : .clear)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            Label("Preferences save automatically", systemImage: "checkmark.circle.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.msSecondaryLabel)
                .padding(16)
        }
        .frame(width: 210)
        .background(Color.msSecondaryBackground.opacity(0.55))
    }

    private var settingsDetail: some View {
        VStack(spacing: 0) {
            SettingsPageHeader(
                title: selectedPane.title,
                subtitle: selectedPane.subtitle,
                icon: selectedPane.icon,
                tint: selectedPane.tint
            )
            Divider()

            ScrollView {
                Group {
                    switch selectedPane {
                    case .general:
                        GeneralSettings(viewModel: viewModel)
                    case .scanning:
                        ScanSettings(viewModel: viewModel)
                    case .notifications:
                        NotificationSettings(viewModel: viewModel)
                    case .privacy:
                        PrivacySettings(viewModel: viewModel, permissionManager: environment.permissionManager)
                    case .about:
                        AboutSettings()
                    }
                }
                .frame(maxWidth: 720)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsPageHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(tint)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.msLabel)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.msBackground)
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let tint: Color
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        tint: Color = .msAccent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.msLabel)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.msSecondaryLabel)
                    }
                }
                Spacer()
            }
            .padding(16)

            Divider().padding(.leading, 46)

            content.padding(16)
        }
        .background(Color.msSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.msSeparator.opacity(0.55), lineWidth: 1)
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let detail: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.msSecondaryLabel)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.msLabel)
                    Text(detail)
                        .font(.system(size: 10))
                        .foregroundColor(.msSecondaryLabel)
                }
            }
        }
        .toggleStyle(.switch)
    }
}
