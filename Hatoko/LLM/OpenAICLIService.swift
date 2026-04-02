import Foundation

/// Experimental: Uses the `openai` Python package CLI.
/// Install via `pip install openai`, then run as:
/// `openai api chat.completions.create -m gpt-4o -g user "prompt"`
final class OpenAICLIService: LLMService, Sendable {

    private let executablePath: String

    init(executablePath: String = "openai") {
        self.executablePath = executablePath
    }

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        let prompt = buildPrompt(messages: messages)
        let args = buildArguments(prompt: prompt, systemPrompt: systemPrompt)
        return try await CLIRunner.run(executablePath: executablePath, arguments: args)
    }

    // MARK: - Internal helpers exposed for testing

    func buildPrompt(messages: [LLMMessage]) -> String {
        var parts: [String] = []
        for message in messages {
            switch message.role {
            case .user:
                parts.append(message.content)
            case .assistant:
                parts.append("[ASSISTANT]\n\(message.content)")
            }
        }
        return parts.joined(separator: "\n\n")
    }

    func buildArguments(prompt: String, systemPrompt: String?) -> [String] {
        var args = ["api", "chat.completions.create", "-m", "gpt-4o"]
        if let systemPrompt {
            args.append(contentsOf: ["-g", "system", systemPrompt])
        }
        args.append(contentsOf: ["-g", "user", prompt])
        return args
    }
}
