import SwiftUI

struct SettingsView: View {

    private static let apiKeyKeychainKey = LLMBackend.apiKeyKeychainKey

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
                }
            }

            if selectedBackend == .disabled {
                Section("LLM 無効") {
                    Text("LLM機能は無効です。Ctrl+Spaceは動作しません。")
                        .foregroundStyle(.secondary)
                }
            }

            if selectedBackend == .claudeAPI {
                Section("Claude API") {
                    SecureField("API Key", text: $apiKey)
                        .accessibilityLabel("Claude API キー")
                    Button("保存") {
                        saveAPIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    if isSaved {
                        Text("保存しました")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            if selectedBackend == .claudeCLI {
                Section("Claude CLI") {
                    TextField("パス", text: $cliPath, prompt: Text("自動検出"))
                        .accessibilityLabel("Claude CLI パス")
                    Button("保存") {
                        saveCLIPath()
                    }
                    .buttonStyle(.borderedProminent)
                    Text("claude -p でプロンプトを送信します")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("キーバインド") {
                Text("Ctrl + Space: LLMアシストモード")
                    .foregroundStyle(.secondary)
                Text("Ctrl + Space (LLM入力中): 日本語/英語切替")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, idealWidth: 420, minHeight: 200, idealHeight: 320)
        .onAppear {
            apiKey = KeychainHelper.load(key: Self.apiKeyKeychainKey) ?? ""
            selectedBackend = .current
            cliPath = UserDefaults.standard.string(forKey: LLMBackend.cliPathDefaultsKey) ?? ""
        }
    }

    private func saveAPIKey() {
        do {
            try KeychainHelper.save(key: Self.apiKeyKeychainKey, value: apiKey)
            showSaved()
        } catch {
            NSLog("[Hatoko] Failed to save API key: \(error)")
        }
    }

    private func saveCLIPath() {
        let trimmed = cliPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: LLMBackend.cliPathDefaultsKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: LLMBackend.cliPathDefaultsKey)
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
