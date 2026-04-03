import Foundation

/// Experimental: Uses the `openai` Python package CLI.
/// Install via `pip install openai`, then run as:
/// `openai api chat.completions.create -m gpt-4o -g user "prompt"`
final class OpenAICLIService: LLMService, Sendable {

    private let executablePath: String
    private let model: String

    init(executablePath: String = "openai", model: String = "gpt-4o") {
        self.executablePath = executablePath
        self.model = model
    }

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        let prompt = CLIRunner.buildPrompt(messages: messages)
        let args = buildArguments(prompt: prompt, systemPrompt: systemPrompt)
        return try await CLIRunner.run(executablePath: executablePath, arguments: args)
    }

    // MARK: - Internal helpers exposed for testing

    func buildArguments(prompt: String, systemPrompt: String?) -> [String] {
        var args = ["api", "chat.completions.create", "-m", model]
        if let systemPrompt {
            args.append(contentsOf: ["-g", "system", systemPrompt])
        }
        args.append(contentsOf: ["-g", "user", prompt])
        return args
    }
}
