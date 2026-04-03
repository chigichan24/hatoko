import SwiftUI

struct SettingsBackendSection: View {

    let backend: LLMBackend
    @Binding var apiKey: String
    @Binding var cliPath: String
    @Binding var isSaved: Bool

    var body: some View {
        switch backend.configKind {
        case .disabled:
            disabledSection
        case .api(let keychainKey, _):
            apiSection(keychainKey: keychainKey)
        case .cli(let defaultsKey):
            cliSection(defaultsKey: defaultsKey)
        }
    }

    private var disabledSection: some View {
        Section("LLM 無効") {
            Text("LLM機能は無効です。Ctrl+Spaceは動作しません。")
                .foregroundStyle(.secondary)
        }
    }

    private func apiSection(keychainKey: String) -> some View {
        Section(backend.displayName) {
            SecureField("API Key", text: $apiKey)
                .accessibilityLabel("\(backend.displayName) API キー")
            Button("保存") {
                saveAPIKey(keychainKey: keychainKey)
            }
            .buttonStyle(.borderedProminent)
            if isSaved {
                Text("保存しました")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }

    private func cliSection(defaultsKey: String) -> some View {
        Section(backend.displayName) {
            TextField("パス", text: $cliPath, prompt: Text("自動検出"))
                .accessibilityLabel("\(backend.displayName) パス")
            Button("保存") {
                saveCLIPath(defaultsKey: defaultsKey)
            }
            .buttonStyle(.borderedProminent)
            Text(backend.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func saveAPIKey(keychainKey: String) {
        do {
            try KeychainHelper.save(key: keychainKey, value: apiKey)
            showSaved()
        } catch {
            NSLog("[Hatoko] Failed to save API key: \(error)")
        }
    }

    private func saveCLIPath(defaultsKey: String) {
        let trimmed = cliPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: defaultsKey)
        }
        showSaved()
    }

    private func showSaved() {
        isSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSaved = false
        }
    }
}
