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
        
        // 3. 履歴を復元してセッションを作成
        let session = LanguageModelSession(restoring: transcript)
        
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
            entries.append(.instructions(Instructions { systemPrompt }))
        }
        
        for message in history {
            switch message.role {
            case .user:
                entries.append(.prompt(Prompt(content: message.content)))
            case .assistant:
                entries.append(.response(Response(content: message.content)))
            }
        }
        
        return Transcript(entries: entries)
    }
}
