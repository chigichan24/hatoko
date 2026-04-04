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
        Section(L10n.Settings.Backend.Disabled.title) {
            Text(L10n.Settings.Backend.Disabled.description)
                .foregroundStyle(.secondary)
        }
    }

    private func apiSection(keychainKey: String) -> some View {
        Section(backend.displayName) {
            SecureField(L10n.Settings.Backend.apiKey, text: $apiKey)
                .accessibilityLabel(L10n.Settings.Backend.apiKeyAccessibility(backend.displayName))
            Button(L10n.Settings.Backend.save) {
                saveAPIKey(keychainKey: keychainKey)
            }
            .buttonStyle(.borderedProminent)
            if isSaved {
                Text(L10n.Settings.Backend.saved)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }

    private func cliSection(defaultsKey: String) -> some View {
        Section(backend.displayName) {
            TextField(L10n.Settings.Backend.pathLabel, text: $cliPath, prompt: Text(L10n.Settings.Backend.pathPlaceholder))
                .accessibilityLabel(L10n.Settings.Backend.pathAccessibility(backend.displayName))
            Button(L10n.Settings.Backend.save) {
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
