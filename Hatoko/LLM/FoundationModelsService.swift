import Foundation
import FoundationModels

final class FoundationModelsService: LLMService, Sendable {

    // The on-device model has a 4,096-token context window (input + output combined).
    // Reserve tokens for the system prompt (~200), current user message, and generated output.
    static let maxHistoryMessages = 4
    static let maxHistoryMessageLength = 300

    private static let generationOptions = GenerationOptions(temperature: 0.5)

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        guard let lastMessage = messages.last, lastMessage.role == .user else {
            return ""
        }

        let history = Self.truncateHistory(Array(messages.dropLast()))

        let transcript = buildTranscript(history: history, systemPrompt: systemPrompt)
        let session = LanguageModelSession(transcript: transcript)

        do {
            let response = try await session.respond(to: lastMessage.content, options: Self.generationOptions)
            let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !content.isEmpty else {
                throw LLMServiceError.emptyContent
            }

            return content
        } catch {
            if let serviceError = error as? LLMServiceError {
                throw serviceError
            }
            print("FoundationModels Error: \(error)")
            throw LLMServiceError.invalidResponse
        }
    }

    // MARK: - Internal for testing

    static func truncateHistory(_ history: [LLMMessage]) -> [LLMMessage] {
        history.suffix(maxHistoryMessages).map { message in
            if message.content.count > maxHistoryMessageLength {
                return LLMMessage(role: message.role, content: String(message.content.prefix(maxHistoryMessageLength)))
            }
            return message
        }
    }

    func buildTranscript(history: [LLMMessage], systemPrompt: String?) -> Transcript {
        var entries: [Transcript.Entry] = []

        if let systemPrompt, !systemPrompt.isEmpty {
            let textSegment = Transcript.TextSegment(content: systemPrompt)
            entries.append(.instructions(Transcript.Instructions(segments: [.text(textSegment)], toolDefinitions: [])))
        }

        for message in history {
            let textSegment = Transcript.TextSegment(content: message.content)
            switch message.role {
            case .user:
                entries.append(.prompt(Transcript.Prompt(segments: [.text(textSegment)])))
            case .assistant:
                entries.append(.response(Transcript.Response(assetIDs: [], segments: [.text(textSegment)])))
            }
        }

        return Transcript(entries: entries)
    }
}
