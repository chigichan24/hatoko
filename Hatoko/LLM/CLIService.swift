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
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = ["-p", prompt]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw CLIServiceError.launchFailed(error)
        }

        // Read pipe data and wait for exit on a detached task to avoid
        // deadlock when output exceeds the pipe buffer.
        let result: (output: Data, error: Data, status: Int32) = await Task.detached {
            let outData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return (outData, errData, process.terminationStatus)
        }.value

        let output = String(data: result.output, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if result.status != 0 {
            let errorMessage = String(data: result.error, encoding: .utf8) ?? "Unknown error"
            throw CLIServiceError.processExited(status: result.status, stderr: errorMessage)
        }
        if output.isEmpty {
            throw CLIServiceError.emptyOutput
        }
        return output
    }
}

enum CLIServiceError: Error {
    case launchFailed(any Error)
    case processExited(status: Int32, stderr: String)
    case emptyOutput
}
