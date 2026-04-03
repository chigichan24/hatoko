import Foundation

enum BackendConfigKind: Sendable {
    case disabled
    case api(keychainKey: String, envVariable: String)
    case cli(defaultsKey: String)
}

enum LLMBackend: String, CaseIterable, Sendable {
    case disabled   = "disabled"
    case claudeAPI  = "claude_api"
    case claudeCLI  = "claude_cli"
    case openaiAPI  = "openai_api"
    case openaiCLI  = "openai_cli"
    case geminiAPI  = "gemini_api"
    case geminiCLI  = "gemini_cli"

    var displayName: String {
        switch self {
        case .disabled: "無効 (Disabled)"
        case .claudeAPI: "Claude API"
        case .claudeCLI: "Claude CLI (claude -p)"
        case .openaiAPI: "OpenAI API"
        case .openaiCLI: "OpenAI CLI (実験的)"
        case .geminiAPI: "Gemini API"
        case .geminiCLI: "Gemini CLI (実験的)"
        }
    }

    var description: String {
        switch self {
        case .disabled: "LLM機能を使用しません"
        case .claudeAPI: "Anthropic API経由。API Keyが必要"
        case .claudeCLI: "ローカルのClaude CLIを使用。API Key不要"
        case .openaiAPI: "OpenAI API経由。API Keyが必要"
        case .openaiCLI: "openai CLIを使用（実験的）。Pythonパッケージが必要"
        case .geminiAPI: "Google Gemini API経由。API Keyが必要"
        case .geminiCLI: "gemini CLIを使用（実験的）。gemini-cliが必要"
        }
    }

    var isEnabled: Bool { self != .disabled }

    var configKind: BackendConfigKind {
        switch self {
        case .disabled: .disabled
        case .claudeAPI: .api(keychainKey: "claude_api_key", envVariable: "ANTHROPIC_API_KEY")
        case .openaiAPI: .api(keychainKey: "openai_api_key", envVariable: "OPENAI_API_KEY")
        case .geminiAPI: .api(keychainKey: "gemini_api_key", envVariable: "GEMINI_API_KEY")
        case .claudeCLI: .cli(defaultsKey: "claude_cli_path")
        case .openaiCLI: .cli(defaultsKey: "openai_cli_path")
        case .geminiCLI: .cli(defaultsKey: "gemini_cli_path")
        }
    }

    // MARK: - Persistence

    private static let userDefaultsKey = "llm_backend"

    static var current: LLMBackend {
        get {
            guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
                  let backend = LLMBackend(rawValue: raw) else {
                return .disabled
            }
            return backend
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: userDefaultsKey)
        }
    }

    static func migrateIfNeeded() {
        guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey) else { return }
        let migration: [String: String] = ["api": "claude_api", "cli": "claude_cli"]
        if let newRaw = migration[raw] {
            UserDefaults.standard.set(newRaw, forKey: userDefaultsKey)
        }
    }

    // MARK: - Service Factory

    func createService() throws -> any LLMService {
        switch self {
        case .disabled:
            throw LLMBackendError.disabled
        case .claudeAPI, .openaiAPI, .geminiAPI:
            return try createAPIService()
        case .claudeCLI, .openaiCLI, .geminiCLI:
            return createCLIService()
        }
    }

    private func createAPIService() throws -> any LLMService {
        let apiKey = try resolveAPIKey()
        switch self {
        case .claudeAPI: return ClaudeService(apiKey: apiKey)
        case .openaiAPI: return OpenAIService(apiKey: apiKey)
        case .geminiAPI: return GeminiService(apiKey: apiKey)
        default: fatalError("unreachable: non-API case in createAPIService")
        }
    }

    private func createCLIService() -> any LLMService {
        let path = resolvedCLIPathWithUserDefault()
        switch self {
        case .claudeCLI: return ClaudeCLIService(executablePath: path)
        case .openaiCLI: return OpenAICLIService(executablePath: path)
        case .geminiCLI: return GeminiCLIService(executablePath: path)
        default: fatalError("unreachable: non-CLI case in createCLIService")
        }
    }

    // MARK: - API Key Resolution

    private func resolveAPIKey() throws -> String {
        guard case .api(let keychainKey, let envVariable) = configKind else {
            throw LLMBackendError.apiKeyNotConfigured
        }
        guard let apiKey = KeychainHelper.load(key: keychainKey)
            ?? ProcessInfo.processInfo.environment[envVariable],
              !apiKey.isEmpty else {
            throw LLMBackendError.apiKeyNotConfigured
        }
        return apiKey
    }

    // MARK: - CLI Path Resolution

    private func resolvedCLIPathWithUserDefault() -> String {
        if case .cli(let defaultsKey) = configKind,
           let path = UserDefaults.standard.string(forKey: defaultsKey) {
            return path
        }
        return resolvedCLIPath()
    }

    private func resolvedCLIPath() -> String {
        switch self {
        case .claudeCLI:
            return Self.findExecutable(name: "claude", extraPaths: [
                NSString("~/.local/bin/claude").expandingTildeInPath,
                NSString("~/.claude/local/claude").expandingTildeInPath,
            ])
        case .openaiCLI:
            return Self.findExecutable(name: "openai", extraPaths: [])
        case .geminiCLI:
            return Self.findExecutable(name: "gemini", extraPaths: [
                NSString("~/.local/bin/gemini").expandingTildeInPath,
            ])
        default:
            return ""
        }
    }

    private static func findExecutable(name: String, extraPaths: [String]) -> String {
        let basePaths = ["/usr/local/bin/", "/opt/homebrew/bin/"]
        let candidates = extraPaths + basePaths.map { $0 + name }
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return name
    }
}

enum LLMBackendError: Error {
    case apiKeyNotConfigured
    case disabled
}
