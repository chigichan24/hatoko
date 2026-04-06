import Foundation
import FoundationModels

final class FoundationModelsService: LLMService, Sendable {

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        // 1. Extract the last user message (this will be the current prompt)
        guard let lastMessage = messages.last, lastMessage.role == .user else {
            return ""
        }
        
        // 2. Build the previous history as a Transcript
        let transcript = buildTranscript(history: Array(messages.dropLast()), systemPrompt: systemPrompt)
        
        // 3. Create a session, passing the transcript
        let session = LanguageModelSession(transcript: transcript)
        
        do {
            // 4. Generate a response with the latest message
            let response = try await session.respond(to: lastMessage.content)
            return response.content
        } catch {
            print("FoundationModels Error: \(error)")
            throw LLMServiceError.invalidResponse
        }
    }
    
    // MARK: - Internal for testing
    
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
