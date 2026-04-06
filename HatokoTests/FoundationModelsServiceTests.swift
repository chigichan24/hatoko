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

        // Transcript should have 3 entries: system instructions, user prompt, and assistant response
        #expect(transcript.count == 3)

        // Check types if possible (based on search results, Entry is an enum)
        // Note: Actual implementation details might vary slightly, but this is the general idea
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
}
