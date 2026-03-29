import Foundation

enum LLMBackend: String, CaseIterable, Sendable {
    case claudeAPI = "api"
    case claudeCLI = "cli"

    static let apiKeyKeychainKey = "claude_api_key"
    static let cliPathDefaultsKey = "claude_cli_path"

    var displayName: String {
        switch self {
        case .claudeAPI: "Claude API"
        case .claudeCLI: "Claude CLI (claude -p)"
        }
    }

    var description: String {
        switch self {
        case .claudeAPI: "クラウドAPI経由。API Keyが必要"
        case .claudeCLI: "ローカルのClaude CLIを使用。API Key不要"
        }
    }

    private static let userDefaultsKey = "llm_backend"

    static var current: LLMBackend {
        get {
            guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
                  let backend = LLMBackend(rawValue: raw) else {
                return .claudeCLI
            }
            return backend
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: userDefaultsKey)
        }
    }

    func createService() throws -> any LLMService {
        switch self {
        case .claudeAPI:
            guard let apiKey = KeychainHelper.load(key: Self.apiKeyKeychainKey)
                ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
                  !apiKey.isEmpty else {
                throw LLMBackendError.apiKeyNotConfigured
            }
            return ClaudeService(apiKey: apiKey)
        case .claudeCLI:
            let path = UserDefaults.standard.string(forKey: Self.cliPathDefaultsKey) ?? resolvedCLIPath()
            return CLIService(executablePath: path)
        }
    }

    private func resolvedCLIPath() -> String {
        // Common installation paths for Claude CLI
        let candidates = [
            NSString("~/.local/bin/claude").expandingTildeInPath,
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            NSString("~/.claude/local/claude").expandingTildeInPath,
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return "claude"
    }
}

enum LLMBackendError: Error {
    case apiKeyNotConfigured
}
