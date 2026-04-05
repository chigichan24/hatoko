import SwiftUI

struct SettingsView: View {

    @State private var apiKey: String = ""
    @State private var selectedBackend: LLMBackend = .current
    @State private var cliPath: String = ""
    @State private var isSaved = false

    var body: some View {
        Form {
            Section(L10n.Settings.SectionHeader.llmBackend) {
                Picker(L10n.Settings.Picker.backend, selection: $selectedBackend) {
                    ForEach(LLMBackend.allCases, id: \.self) { backend in
                        VStack(alignment: .leading) {
                            Text(backend.displayName)
                            Text(backend.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(backend)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: selectedBackend) {
                    LLMBackend.current = selectedBackend
                    loadSettingsForBackend(selectedBackend)
                }
            }

            SettingsBackendSection(
                backend: selectedBackend,
                apiKey: $apiKey,
                cliPath: $cliPath,
                isSaved: $isSaved
            )

            Section(L10n.Settings.SectionHeader.keybinding) {
                Text(L10n.Settings.Keybinding.llmAssist)
                    .foregroundStyle(.secondary)
                Text(L10n.Settings.Keybinding.toggleLanguage)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, idealWidth: 420, minHeight: 200, idealHeight: 400)
        .onAppear {
            selectedBackend = .current
            loadSettingsForBackend(selectedBackend)
        }
    }

    private func loadSettingsForBackend(_ backend: LLMBackend) {
        isSaved = false
        switch backend.configKind {
        case .disabled:
            apiKey = ""
            cliPath = ""
        case .api(let keychainKey, _):
            cliPath = ""
            Task.detached {
                let loaded = KeychainHelper.load(key: keychainKey) ?? ""
                await MainActor.run { apiKey = loaded }
            }
        case .cli(let defaultsKey):
            apiKey = ""
            cliPath = UserDefaults.standard.string(forKey: defaultsKey) ?? ""
        }
    }
}
