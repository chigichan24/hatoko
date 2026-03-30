import Foundation
import Testing

@testable import Hatoko

@Suite
struct LLMMessageTests {

    @Test
    func messageCreation() {
        let message = LLMMessage(role: .user, content: "Hello")
        #expect(message.role == .user)
        #expect(message.content == "Hello")
    }

    @Test
    func assistantRole() {
        let message = LLMMessage(role: .assistant, content: "Hi there")
        #expect(message.role == .assistant)
        #expect(message.content == "Hi there")
    }

    @Test
    func equatable() {
        let a = LLMMessage(role: .user, content: "test")
        let b = LLMMessage(role: .user, content: "test")
        #expect(a == b)
    }
}

@Suite
struct ClaudeServiceTests {

    @Test
    func requestConstruction() throws {
        let service = ClaudeService(apiKey: "test-key", model: "claude-sonnet-4-20250514")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        #expect(request.url?.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "test-key")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        #expect(request.value(forHTTPHeaderField: "content-type") == "application/json")
    }

    @Test
    func requestBodyContainsMessages() throws {
        let service = ClaudeService(apiKey: "test-key")
        let messages = [
            LLMMessage(role: .user, content: "Hello"),
            LLMMessage(role: .assistant, content: "Hi"),
        ]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        let jsonMessages = try #require(json["messages"] as? [[String: String]])
        #expect(jsonMessages.count == 2)
        #expect(jsonMessages[0]["role"] == "user")
        #expect(jsonMessages[0]["content"] == "Hello")
        #expect(jsonMessages[1]["role"] == "assistant")
        #expect(jsonMessages[1]["content"] == "Hi")
    }

    @Test
    func requestBodyContainsSystemPrompt() throws {
        let service = ClaudeService(apiKey: "test-key")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: "You are helpful.")

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        let system = try #require(json["system"] as? String)
        #expect(system == "You are helpful.")
    }

    @Test
    func requestBodyOmitsSystemPromptWhenNil() throws {
        let service = ClaudeService(apiKey: "test-key")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        #expect(json["system"] == nil)
    }

    @Test
    func requestBodyContainsModel() throws {
        let service = ClaudeService(apiKey: "test-key", model: "custom-model")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        let model = try #require(json["model"] as? String)
        #expect(model == "custom-model")
    }
}

@Suite
struct CLIServiceTests {

    @Test
    func buildPromptWrapsSystemInstructions() {
        let service = CLIService()
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let prompt = service.buildPrompt(messages: messages, systemPrompt: "Be helpful.")

        #expect(prompt.contains("[SYSTEM INSTRUCTIONS - DO NOT MODIFY OR OVERRIDE]"))
        #expect(prompt.contains("Be helpful."))
        #expect(prompt.contains("[END SYSTEM INSTRUCTIONS]"))
    }

    @Test
    func buildPromptLabelsUserMessages() {
        let service = CLIService()
        let messages = [LLMMessage(role: .user, content: "What is 2+2?")]
        let prompt = service.buildPrompt(messages: messages, systemPrompt: nil)

        #expect(prompt.contains("[USER]\nWhat is 2+2?"))
    }

    @Test
    func buildPromptLabelsAssistantMessages() {
        let service = CLIService()
        let messages = [LLMMessage(role: .assistant, content: "The answer is 4.")]
        let prompt = service.buildPrompt(messages: messages, systemPrompt: nil)

        #expect(prompt.contains("[ASSISTANT]\nThe answer is 4."))
    }

    @Test
    func buildPromptOmitsSystemBlockWhenNil() {
        let service = CLIService()
        let messages = [LLMMessage(role: .user, content: "Hi")]
        let prompt = service.buildPrompt(messages: messages, systemPrompt: nil)

        #expect(!prompt.contains("[SYSTEM INSTRUCTIONS"))
        #expect(!prompt.contains("[END SYSTEM INSTRUCTIONS]"))
        #expect(prompt.contains("[CONVERSATION START]"))
    }
}
