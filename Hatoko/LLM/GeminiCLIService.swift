import Foundation

/// Experimental: Uses the Gemini CLI from google-gemini/gemini-cli.
/// See https://github.com/google-gemini/gemini-cli for installation.
/// Usage: `gemini -p "prompt"`
final class GeminiCLIService: LLMService, Sendable {

    private let executablePath: String

    init(executablePath: String = "gemini") {
        self.executablePath = executablePath
    }

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        let prompt = CLIRunner.buildPrompt(messages: messages)
        let args = buildArguments(prompt: prompt, systemPrompt: systemPrompt)
        return try await CLIRunner.run(executablePath: executablePath, arguments: args)
    }

    // MARK: - Internal helpers exposed for testing

    func buildArguments(prompt: String, systemPrompt: String?) -> [String] {
        var args = ["-p", prompt]
        if let systemPrompt {
            args.append(contentsOf: ["--system-prompt", systemPrompt])
        }
        return args
    }
}
