import SwiftUI

struct SettingsView: View {

    private static let apiKeyKeychainKey = "claude_api_key"

    @State private var apiKey: String = ""
    @State private var isSaved = false

    var body: some View {
        Form {
            Section {
                Text("Hatoko 設定")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Section("Claude API") {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)

                HStack {
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

            Section("キーバインド") {
                Text("Ctrl + Space: LLMアシストモード")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 280)
        .onAppear {
            apiKey = KeychainHelper.load(key: Self.apiKeyKeychainKey) ?? ""
        }
    }

    private func saveAPIKey() {
        do {
            try KeychainHelper.save(key: Self.apiKeyKeychainKey, value: apiKey)
            isSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isSaved = false
            }
        } catch {
            NSLog("[Hatoko] Failed to save API key: \(error)")
        }
    }
}
