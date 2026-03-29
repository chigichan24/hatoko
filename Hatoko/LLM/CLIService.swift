import Foundation

final class CLIService: LLMService, Sendable {

    private let executablePath: String

    init(executablePath: String = "/usr/local/bin/claude") {
        self.executablePath = executablePath
    }

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        let prompt = buildPrompt(messages: messages, systemPrompt: systemPrompt)
        return try await runCLI(prompt: prompt)
    }

    private func buildPrompt(messages: [LLMMessage], systemPrompt: String?) -> String {
        var parts: [String] = []
        if let systemPrompt {
            parts.append(systemPrompt)
        }
        // For CLI mode, concatenate messages into a single prompt.
        // The last user message is the primary request.
        for message in messages {
            switch message.role {
            case .user:
                parts.append(message.content)
            case .assistant:
                parts.append("Previous response: \(message.content)")
            }
        }
        return parts.joined(separator: "\n\n")
    }

    private func runCLI(prompt: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = ["-p", prompt]

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            process.terminationHandler = { proc in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if proc.terminationStatus != 0 {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: CLIServiceError.processExited(
                        status: proc.terminationStatus,
                        stderr: errorMessage
                    ))
                } else if output.isEmpty {
                    continuation.resume(throwing: CLIServiceError.emptyOutput)
                } else {
                    continuation.resume(returning: output)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: CLIServiceError.launchFailed(error))
            }
        }
    }
}

enum CLIServiceError: Error {
    case launchFailed(any Error)
    case processExited(status: Int32, stderr: String)
    case emptyOutput
}
