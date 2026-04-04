import Foundation

enum CLIRunner {

    struct ProcessResult: Sendable {
        let output: Data
        let error: Data
        let terminationStatus: Int32
    }

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

    struct ResolvedShebang: Equatable {
        let interpreterPath: String
        let interpreterArgs: [String]
    }

    static func resolveShebang(atPath path: String) -> ResolvedShebang? {
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { handle.closeFile() }
        let data = handle.readData(ofLength: 256)
        guard let header = String(data: data, encoding: .utf8),
              let firstLine = header.components(separatedBy: .newlines).first,
              firstLine.hasPrefix("#!") else {
            return nil
        }

        let shebang = String(firstLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        guard shebang.hasPrefix("/usr/bin/env") else { return nil }

        var parts = shebang.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        parts.removeFirst() // remove "/usr/bin/env"
        if parts.first == "-S" {
            parts.removeFirst()
        }
        guard let interpreterName = parts.first else { return nil }
        let interpreterArgs = Array(parts.dropFirst())

        let searchPaths = ["/opt/homebrew/bin/", "/usr/local/bin/", "/usr/bin/"]
        guard let resolvedPath = searchPaths
            .map({ $0 + interpreterName })
            .first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            return nil
        }

        return ResolvedShebang(interpreterPath: resolvedPath, interpreterArgs: interpreterArgs)
    }

    static func run(
        executablePath: String,
        arguments: [String],
        currentDirectoryPath: String = "/tmp"
    ) async throws -> String {
        let process = Process()

        if let shebang = resolveShebang(atPath: executablePath) {
            process.executableURL = URL(fileURLWithPath: shebang.interpreterPath)
            process.arguments = shebang.interpreterArgs + [executablePath] + arguments
        } else {
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
        }
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
        let result = await Task.detached {
            let outData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return ProcessResult(output: outData, error: errData, terminationStatus: process.terminationStatus)
        }.value

        let output = String(data: result.output, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if result.terminationStatus != 0 {
            let errorMessage = String(data: result.error, encoding: .utf8) ?? "Unknown error"
            throw CLIRunnerError.processExited(status: result.terminationStatus, stderr: errorMessage)
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
