import Foundation
import FoundationModels

final class FoundationModelsService: LLMService, Sendable {

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        // 1. 最後のユーザーメッセージを抽出（これが現在のプロンプトになる）
        guard let lastMessage = messages.last, lastMessage.role == .user else {
            return ""
        }
        
        // 2. それより前の履歴を Transcript として構築
        let transcript = buildTranscript(history: Array(messages.dropLast()), systemPrompt: systemPrompt)
        
        // 3. セッションを作成。transcript を渡す
        let session = LanguageModelSession(transcript: transcript)
        
        do {
            // 4. 最新のメッセージで応答を生成
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
