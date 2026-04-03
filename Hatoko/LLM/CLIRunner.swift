import Foundation

enum CLIRunner {

    static func buildPrompt(messages: [LLMMessage]) -> String {
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

    static func run(
        executablePath: String,
        arguments: [String],
        currentDirectoryPath: String = "/tmp"
    ) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        // Use configurable working directory to avoid TCC prompts for
        // protected user directories (Music, Photos, etc.) when the
        // CLI process is spawned from the IME process context.
        process.currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw CLIRunnerError.launchFailed(error)
        }

        // Read pipe data and wait for exit on a detached task to avoid
        // deadlock when output exceeds the pipe buffer.
        let (outputData, errorData, terminationStatus) = await Task.detached {
            let outData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return (outData, errData, process.terminationStatus)
        }.value

        let output = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw CLIRunnerError.processExited(status: terminationStatus, stderr: errorMessage)
        }
        if output.isEmpty {
            throw CLIRunnerError.emptyOutput
        }
        return output
    }
}

enum CLIRunnerError: Error {
    case launchFailed(any Error)
    case processExited(status: Int32, stderr: String)
    case emptyOutput
}
