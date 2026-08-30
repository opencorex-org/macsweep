import SwiftUI

public struct GeneralSettings: View {
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
        Form {
            Section(header: Text("Startup & Updates")) {
                Toggle("Launch MacSweep at login", isOn: $viewModel.launchAtLogin)
                Toggle("Automatically check for updates", isOn: $viewModel.autoCheckUpdates)
            }

            Section(header: Text("App Language")) {
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
                .pickerStyle(.menu)

                Text("Restart MacSweep after changing the language.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
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
