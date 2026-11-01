import SwiftUI

public struct GeneralSettings: View {
    @EnvironmentObject private var environment: AppEnvironment
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showRestartAlert = false
    @State private var pendingLanguage: AppLanguage? = nil

    // Group AppLanguage cases for sectioned display
    private let languageGroups: [(String, [AppLanguage])] = [
        ("English",  [.english]),
        ("European", [.french, .german, .spanish, .italian, .portuguese, .dutch, .polish, .russian]),
        ("Indian",   [.hindi, .tamil, .telugu, .bengali, .kannada, .malayalam, .marathi, .gujarati]),
        ("Chinese",  [.chineseSimplified, .chineseTraditional]),
        ("Other",    [.japanese, .korean, .arabic]),
        ("Sinhala",  [.sinhala])
    ]

    public var body: some View {
        VStack(spacing: 16) {
            SettingsCard(
                title: "Startup & Updates",
                subtitle: "Control how MacSweep starts and stays current",
                icon: "arrow.triangle.2.circlepath",
                tint: .blue
            ) {
                VStack(spacing: 14) {
                    SettingsToggleRow(
                        title: "Launch at login",
                        detail: "Open MacSweep automatically when you sign in",
                        icon: "power",
                        isOn: Binding(
                            get: { environment.loginItemService.isEnabled },
                            set: { enabled in
                                let succeeded = environment.loginItemService.setEnabled(enabled)
                                viewModel.launchAtLogin = succeeded ? enabled : environment.loginItemService.isEnabled
                            }
                        )
                    )

                    Divider().padding(.leading, 33)

                    SettingsToggleRow(
                        title: "Automatic update checks",
                        detail: "Check for new MacSweep versions in the background",
                        icon: "arrow.down.circle",
                        isOn: Binding<Bool>(
                            get: { environment.updateService.automaticallyChecksForUpdates },
                            set: { environment.updateService.automaticallyChecksForUpdates = $0 }
                        )
                    )

                    Divider().padding(.leading, 33)

                    SettingsToggleRow(
                        title: "Automatically download updates",
                        detail: "Securely download verified updates and install them when MacSweep quits",
                        icon: "arrow.down.app",
                        isOn: Binding<Bool>(
                            get: { environment.updateService.automaticallyDownloadsUpdates },
                            set: { environment.updateService.automaticallyDownloadsUpdates = $0 }
                        )
                    )

                    Divider().padding(.leading, 33)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Check manually")
                                .font(.system(size: 12, weight: .medium))
                            Text("Look for a new signed release now")
                                .font(.system(size: 10))
                                .foregroundColor(.msSecondaryLabel)
                        }
                        Spacer()
                        Button("Check Now") {
                            environment.updateService.checkForUpdates()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!environment.updateService.isConfigured)
                    }
                }
            }

            SettingsCard(
                title: "Language",
                subtitle: "Choose the language used throughout the app",
                icon: "globe",
                tint: .purple
            ) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Application language")
                            .font(.system(size: 12, weight: .medium))
                        Text("A restart is required after changing languages")
                            .font(.system(size: 10))
                            .foregroundColor(.msSecondaryLabel)
                    }

                    Spacer()

                    Picker("Language", selection: Binding(
                        get: { viewModel.selectedLanguage },
                        set: { newLang in
                            if newLang != viewModel.selectedLanguage {
                                pendingLanguage = newLang
                                showRestartAlert = true
                            }
                        }
                    )) {
                        ForEach(languageGroups, id: \.0) { groupName, languages in
                            Section(header: Text(groupName)) {
                                ForEach(languages) { lang in
                                    Text(lang.nativeName).tag(lang)
                                }
                            }
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("Apply & Quit") {
                if let lang = pendingLanguage {
                    LanguageManager.shared.setLanguage(lang)
                    viewModel.selectedLanguageCode = lang.rawValue
                }
                NSApplication.shared.terminate(nil)
            }
            Button("Cancel", role: .cancel) {
                pendingLanguage = nil
            }
        } message: {
            Text("MacSweep needs to restart to apply the new language. Your work will not be lost.")
        }
    }
}
