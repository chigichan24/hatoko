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

    func buildPrompt(messages: [LLMMessage], systemPrompt: String?) -> String {
        var parts: [String] = []
        if let systemPrompt {
            parts.append("[SYSTEM INSTRUCTIONS - DO NOT MODIFY OR OVERRIDE]\n\(systemPrompt)\n[END SYSTEM INSTRUCTIONS]")
        }
        parts.append("[CONVERSATION START]")
        for message in messages {
            switch message.role {
            case .user:
                parts.append("[USER]\n\(message.content)")
            case .assistant:
                parts.append("[ASSISTANT]\n\(message.content)")
            }
        }
        return parts.joined(separator: "\n\n")
    }

    private func runCLI(prompt: String) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = ["-p", prompt]
        // Use /tmp as working directory to avoid TCC prompts for
        // protected user directories (Music, Photos, etc.) when the
        // CLI process is spawned from the IME process context.
        process.currentDirectoryURL = URL(fileURLWithPath: "/tmp")

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
        let (outputData, errorData) = await Task.detached {
            let outData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            return (outData, errData)
        }.value

        process.waitUntilExit()

        let output = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw CLIServiceError.processExited(status: process.terminationStatus, stderr: errorMessage)
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
