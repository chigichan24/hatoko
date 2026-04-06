import Foundation
import FoundationModels

final class FoundationModelsService: LLMService, Sendable {

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        // Identify the last user message as the current request.
        // All other messages (history) and system instructions form the session context.
        guard let lastMessage = messages.last, lastMessage.role == .user else {
            return ""
        }

        // Build the transcript containing system instructions and previous conversation history.
        let transcript = buildTranscript(history: Array(messages.dropLast()), systemPrompt: systemPrompt)

        // Initialize the session with the constructed context.
        let session = LanguageModelSession(transcript: transcript)

        do {
            // Generate a response to the latest user request within the session context.
            let response = try await session.respond(to: lastMessage.content)

            // Trim whitespace and newlines to ensure the text is clean and ready for direct insertion,
            // matching the behavior of other services like Gemini and OpenAI.
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

    func buildTranscript(history: [LLMMessage], systemPrompt: String?) -> Transcript {
        var entries: [Transcript.Entry] = []

        // 1. System Prompt (Instructions) always comes first to define the assistant's behavior,
        // similar to system messages in OpenAI or systemInstructions in Gemini.
        if let systemPrompt, !systemPrompt.isEmpty {
            let textSegment = Transcript.TextSegment(content: systemPrompt)
            entries.append(.instructions(Transcript.Instructions(segments: [.text(textSegment)], toolDefinitions: [])))
        }

        // 2. Map history messages to their respective Transcript entry types.
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
