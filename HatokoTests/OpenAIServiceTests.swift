import Foundation
import Testing

@testable import Hatoko

@Suite
struct OpenAIServiceTests {

    @Test
    func requestConstruction() throws {
        let service = OpenAIService(apiKey: "test-key", model: "gpt-4o")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        #expect(request.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test
    func requestBodyContainsMessages() throws {
        let service = OpenAIService(apiKey: "test-key")
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
    func requestBodyContainsSystemPromptAsFirstMessage() throws {
        let service = OpenAIService(apiKey: "test-key")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: "You are helpful.")

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        let jsonMessages = try #require(json["messages"] as? [[String: String]])
        #expect(jsonMessages.count == 2)
        #expect(jsonMessages[0]["role"] == "system")
        #expect(jsonMessages[0]["content"] == "You are helpful.")
        #expect(jsonMessages[1]["role"] == "user")
        #expect(jsonMessages[1]["content"] == "Hello")
    }

    @Test
    func requestBodyOmitsSystemPromptWhenNil() throws {
        let service = OpenAIService(apiKey: "test-key")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        let jsonMessages = try #require(json["messages"] as? [[String: String]])
        #expect(jsonMessages.count == 1)
        #expect(jsonMessages[0]["role"] == "user")
    }

    @Test
    func requestBodyContainsModel() throws {
        let service = OpenAIService(apiKey: "test-key", model: "gpt-4o-mini")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        let model = try #require(json["model"] as? String)
        #expect(model == "gpt-4o-mini")
    }
}
