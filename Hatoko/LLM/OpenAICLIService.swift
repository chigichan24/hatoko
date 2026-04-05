import Foundation

/// Uses the Codex CLI from OpenAI.
/// See https://github.com/openai/codex for installation.
/// Usage: `codex exec "prompt"`
final class OpenAICLIService: LLMService, Sendable {

    private let executablePath: String

    init(executablePath: String = "codex") {
        self.executablePath = executablePath
    }

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        let prompt = CLIRunner.buildPrompt(messages: messages)
        let args = buildArguments(prompt: prompt, systemPrompt: systemPrompt)
        return try await CLIRunner.run(executablePath: executablePath, arguments: args)
    }

    // MARK: - Internal helpers exposed for testing

    func buildArguments(prompt: String, systemPrompt: String?) -> [String] {
        var fullPrompt = prompt
        if let systemPrompt {
            fullPrompt = "[System Instructions]\n\(systemPrompt)\n\n[User Request]\n\(prompt)"
        }
        return ["exec", fullPrompt]
    }
}
