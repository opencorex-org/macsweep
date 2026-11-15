import SwiftUI

private enum SettingsPane: String, CaseIterable, Identifiable {
    case general, appearance, scanning, notifications, privacy, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .scanning: "Scanning"
        case .notifications: "Notifications"
        case .privacy: "Privacy & Access"
        case .about: "About"
        }
    }

    var subtitle: String {
        switch self {
        case .general: "Startup, updates, and language"
        case .appearance: "Choose how MacSweep looks"
        case .scanning: "File detection preferences"
        case .notifications: "Cleanup alerts and banners"
        case .privacy: "Permissions and data handling"
        case .about: "Version and application details"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape.fill"
        case .appearance: "paintbrush.fill"
        case .scanning: "magnifyingglass"
        case .notifications: "bell.badge.fill"
        case .privacy: "hand.raised.fill"
        case .about: "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .general: .blue
        case .appearance: .indigo
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
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.msLabel)
                Text("Make MacSweep work your way")
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 10)

            VStack(spacing: 3) {
                ForEach(SettingsPane.allCases) { pane in
                    Button {
                        withAnimation(.easeInOut(duration: AppTheme.animationDuration)) {
                            selectedPane = pane
                        }
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(pane.tint.opacity(selectedPane == pane ? 0.18 : 0.10))
                                Image(systemName: pane.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(pane.tint)
                            }
                            .frame(width: 25, height: 25)

                            Text(LocalizedStringKey(pane.title))
                                .font(.system(size: 12, weight: selectedPane == pane ? .semibold : .medium))
                                .foregroundColor(.msLabel)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
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
                .padding(14)
        }
        .frame(width: 188)
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
                    case .appearance:
                        AppearanceSettings(viewModel: viewModel)
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
                .frame(maxWidth: 680)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AppearanceSettings: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(spacing: 12) {
            SettingsCard(
                title: "Theme",
                subtitle: "Changes apply instantly throughout MacSweep",
                icon: "circle.lefthalf.filled",
                tint: .indigo
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Theme", selection: themeBinding) {
                        ForEach(AppThemePreference.allCases) { theme in
                            Label {
                                Text(LocalizedStringKey(theme.title))
                            } icon: {
                                Image(systemName: theme.icon)
                            }
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityLabel("Application theme")

                    Label {
                        Text(LocalizedStringKey(viewModel.selectedTheme.detail))
                    } icon: {
                        Image(systemName: viewModel.selectedTheme.icon)
                    }
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: AppTheme.animationDuration), value: viewModel.selectedTheme)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var themeBinding: Binding<AppThemePreference> {
        Binding(
            get: { viewModel.selectedTheme },
            set: { viewModel.selectedTheme = $0 }
        )
    }
}

struct SettingsPageHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(tint)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.msLabel)
                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
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
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.msLabel)
                    if let subtitle {
                        Text(LocalizedStringKey(subtitle))
                            .font(.system(size: 10))
                            .foregroundColor(.msSecondaryLabel)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)

            Divider().padding(.leading, 42)

            content.padding(13)
        }
        .background(Color.msSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
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
                    Text(LocalizedStringKey(title))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.msLabel)
                    Text(LocalizedStringKey(detail))
                        .font(.system(size: 10))
                        .foregroundColor(.msSecondaryLabel)
                }
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .frame(minHeight: 32)
    }
}

struct SettingsInlineRow<Control: View>: View {
    let title: String
    let detail: String?
    let icon: String?
    let control: Control

    init(
        title: String,
        detail: String? = nil,
        icon: String? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.control = control()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.msSecondaryLabel)
                    .frame(width: 22)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.msLabel)
                if let detail {
                    Text(LocalizedStringKey(detail))
                        .font(.system(size: 10))
                        .foregroundColor(.msSecondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 16)
            control
                .controlSize(.small)
        }
        .frame(minHeight: 32)
    }
}
