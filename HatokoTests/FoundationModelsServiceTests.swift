import Foundation
import Testing
import FoundationModels

@testable import Hatoko

@Suite
struct FoundationModelsServiceTests {

    @Test
    func buildTranscript_WithSystemPromptAndHistory() throws {
        let service = FoundationModelsService()
        let history = [
            LLMMessage(role: .user, content: "Hello"),
            LLMMessage(role: .assistant, content: "Hi there!")
        ]
        let systemPrompt = "You are a helpful assistant."

        let transcript = service.buildTranscript(history: history, systemPrompt: systemPrompt)

        #expect(transcript.count == 3)

        var entryIndex = 0
        for entry in transcript {
            switch entryIndex {
            case 0:
                if case .instructions = entry {
                    // Success
                } else {
                    Issue.record("First entry should be instructions")
                }
            case 1:
                if case .prompt = entry {
                    // Success
                } else {
                    Issue.record("Second entry should be prompt")
                }
            case 2:
                if case .response = entry {
                    // Success
                } else {
                    Issue.record("Third entry should be response")
                }
            default:
                break
            }
            entryIndex += 1
        }
    }

    @Test
    func buildTranscript_WithoutSystemPrompt() throws {
        let service = FoundationModelsService()
        let history = [
            LLMMessage(role: .user, content: "Hello")
        ]

        let transcript = service.buildTranscript(history: history, systemPrompt: nil)

        #expect(transcript.count == 1)

        for entry in transcript {
            if case .prompt = entry {
                // Success
            } else {
                Issue.record("Only entry should be prompt")
            }
        }
    }

    // MARK: - truncateHistory

    @Test
    func truncateHistory_limitsMessageCount() {
        let messages = (0..<10).map { LLMMessage(role: .user, content: "Message \($0)") }

        let result = FoundationModelsService.truncateHistory(messages)

        #expect(result.count == FoundationModelsService.maxHistoryMessages)
        #expect(result.first?.content == "Message 6")
        #expect(result.last?.content == "Message 9")
    }

    @Test
    func truncateHistory_truncatesLongMessages() {
        let longContent = String(repeating: "あ", count: 500)
        let messages = [LLMMessage(role: .user, content: longContent)]

        let result = FoundationModelsService.truncateHistory(messages)

        #expect(result.count == 1)
        #expect(result[0].content.count == FoundationModelsService.maxHistoryMessageLength)
    }

    @Test
    func truncateHistory_preservesShortMessages() {
        let messages = [
            LLMMessage(role: .user, content: "短い"),
            LLMMessage(role: .assistant, content: "応答")
        ]

        let result = FoundationModelsService.truncateHistory(messages)

        #expect(result.count == 2)
        #expect(result[0].content == "短い")
        #expect(result[1].content == "応答")
    }
}
