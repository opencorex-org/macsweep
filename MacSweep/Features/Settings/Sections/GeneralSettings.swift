import SwiftUI

public struct GeneralSettings: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var localizationStore: LocalizationStore
    @ObservedObject var viewModel: SettingsViewModel

    // Group AppLanguage cases for sectioned display
    private let languageGroups: [(String, [AppLanguage])] = [
        ("English",  [.english]),
        ("European Union", [
            .bulgarian, .croatian, .czech, .danish, .dutch, .estonian,
            .finnish, .french, .german, .greek, .hungarian, .irish, .italian,
            .latvian, .lithuanian, .maltese, .polish, .portuguese, .romanian,
            .slovak, .slovenian, .spanish, .swedish
        ]),
        ("Additional European", [.portugueseBrazil, .russian]),
        ("Indian",   [.hindi, .tamil, .telugu, .bengali, .kannada, .malayalam, .marathi, .gujarati]),
        ("Chinese",  [.chineseSimplified, .chineseTraditional]),
        ("Other",    [.japanese, .korean, .arabic]),
        ("Sinhala",  [.sinhala])
    ]

    public var body: some View {
        VStack(spacing: 12) {
            SettingsCard(
                title: "Startup & Updates",
                subtitle: "Control how MacSweep starts and stays current",
                icon: "arrow.triangle.2.circlepath",
                tint: .blue
            ) {
                VStack(spacing: 10) {
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

                    SettingsInlineRow(
                        title: "Check manually",
                        detail: "Look for a new signed release now",
                        icon: "arrow.clockwise"
                    ) {
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
                SettingsInlineRow(
                    title: "Application language",
                    detail: "Language changes apply immediately",
                    icon: "character.bubble"
                ) {
                    SettingsMenu(value: localizationStore.language.nativeName, width: 180) {
                        ForEach(languageGroups, id: \.0) { groupName, languages in
                            Section(header: Text(LocalizedStringKey(groupName))) {
                                ForEach(languages) { lang in
                                    Button {
                                        localizationStore.select(lang)
                                    } label: {
                                        if localizationStore.language == lang {
                                            Label(lang.nativeName, systemImage: "checkmark")
                                        } else {
                                            Text(lang.nativeName)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .accessibilityLabel("Application language")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
