import SwiftUI

struct SettingsView: View {

    @State private var apiKey: String = ""
    @State private var selectedBackend: LLMBackend = .current
    @State private var cliPath: String = ""
    @State private var isSaved = false

    var body: some View {
        Form {
            Section("LLM バックエンド") {
                Picker("バックエンド", selection: $selectedBackend) {
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

            Section("キーバインド") {
                Text("Ctrl + Space: LLMアシストモード")
                    .foregroundStyle(.secondary)
                Text("Ctrl + Space (LLM入力中): 日本語/英語切替")
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
        switch backend.configKind {
        case .disabled:
            apiKey = ""
            cliPath = ""
        case .api(let keychainKey, _):
            apiKey = KeychainHelper.load(key: keychainKey) ?? ""
            cliPath = ""
        case .cli(let defaultsKey):
            apiKey = ""
            cliPath = UserDefaults.standard.string(forKey: defaultsKey) ?? ""
        }
        isSaved = false
    }
}
