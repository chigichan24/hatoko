import Foundation

enum LLMBackend: String, CaseIterable, Sendable {
    case claudeAPI = "api"
    case claudeCLI = "cli"

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

    func createService() -> any LLMService {
        switch self {
        case .claudeAPI:
            let apiKey = KeychainHelper.load(key: "claude_api_key")
                ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
                ?? ""
            return ClaudeService(apiKey: apiKey)
        case .claudeCLI:
            let path = UserDefaults.standard.string(forKey: "claude_cli_path") ?? resolvedCLIPath()
            return CLIService(executablePath: path)
        }
    }

    private func resolvedCLIPath() -> String {
        // Common installation paths for Claude CLI
        let candidates = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            NSString("~/.claude/local/claude").expandingTildeInPath,
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return "claude"
    }
}
