import Foundation

final class ClaudeCLIService: LLMService, Sendable {

    private let executablePath: String

    init(executablePath: String = "/usr/local/bin/claude") {
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
        var args = ["-p", prompt]
        if let systemPrompt {
            args.append(contentsOf: ["--system-prompt", systemPrompt])
        }
        return args
    }
}
