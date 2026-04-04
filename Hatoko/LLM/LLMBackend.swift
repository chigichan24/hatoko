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
        case .disabled: L10n.Backend.Disabled.name
        case .claudeAPI: L10n.Backend.ClaudeAPI.name
        case .claudeCLI: L10n.Backend.ClaudeCLI.name
        case .openaiAPI: L10n.Backend.OpenaiAPI.name
        case .openaiCLI: L10n.Backend.OpenaiCLI.name
        case .geminiAPI: L10n.Backend.GeminiAPI.name
        case .geminiCLI: L10n.Backend.GeminiCLI.name
        }
    }

    var description: String {
        switch self {
        case .disabled: L10n.Backend.Disabled.description
        case .claudeAPI: L10n.Backend.ClaudeAPI.description
        case .claudeCLI: L10n.Backend.ClaudeCLI.description
        case .openaiAPI: L10n.Backend.OpenaiAPI.description
        case .openaiCLI: L10n.Backend.OpenaiCLI.description
        case .geminiAPI: L10n.Backend.GeminiAPI.description
        case .geminiCLI: L10n.Backend.GeminiCLI.description
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
        case .claudeAPI:
            return ClaudeService(apiKey: try resolveAPIKey())
        case .openaiAPI:
            return OpenAIService(apiKey: try resolveAPIKey())
        case .geminiAPI:
            return GeminiService(apiKey: try resolveAPIKey())
        case .claudeCLI:
            return ClaudeCLIService(executablePath: resolvedCLIPathWithUserDefault())
        case .openaiCLI:
            return OpenAICLIService(executablePath: resolvedCLIPathWithUserDefault())
        case .geminiCLI:
            return GeminiCLIService(executablePath: resolvedCLIPathWithUserDefault())
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
        case .disabled, .claudeAPI, .openaiAPI, .geminiAPI:
            // Unreachable: only called from createService() via CLI cases.
            preconditionFailure("resolvedCLIPath called on non-CLI backend: \(self)")
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
