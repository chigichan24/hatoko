import Foundation
import Testing

@testable import Hatoko

@Suite
struct GeminiServiceTests {

    @Test
    func requestConstruction() throws {
        let service = GeminiService(apiKey: "test-key", model: "gemini-2.0-flash")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
        #expect(request.url?.absoluteString == urlString)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "test-key")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test
    func requestBodyContainsContents() throws {
        let service = GeminiService(apiKey: "test-key")
        let messages = [
            LLMMessage(role: .user, content: "Hello"),
            LLMMessage(role: .assistant, content: "Hi"),
        ]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let contents = try #require(json["contents"] as? [[String: Any]])

        #expect(contents.count == 2)
        #expect(contents[0]["role"] as? String == "user")
        #expect(contents[1]["role"] as? String == "model")
    }

    @Test
    func assistantRoleMappedToModel() throws {
        let service = GeminiService(apiKey: "test-key")
        let messages = [LLMMessage(role: .assistant, content: "Response")]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let contents = try #require(json["contents"] as? [[String: Any]])

        #expect(contents[0]["role"] as? String == "model")
    }

    @Test
    func requestBodyContainsSystemInstruction() throws {
        let service = GeminiService(apiKey: "test-key")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: "You are helpful.")

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let systemInstruction = try #require(json["systemInstruction"] as? [String: Any])
        let parts = try #require(systemInstruction["parts"] as? [[String: Any]])

        #expect(parts.count == 1)
        #expect(parts[0]["text"] as? String == "You are helpful.")
    }

    @Test
    func requestBodyOmitsSystemInstructionWhenNil() throws {
        let service = GeminiService(apiKey: "test-key")
        let messages = [LLMMessage(role: .user, content: "Hello")]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        #expect(json["systemInstruction"] == nil)
    }

    @Test
    func requestBodyContainsCorrectPartsStructure() throws {
        let service = GeminiService(apiKey: "test-key")
        let messages = [LLMMessage(role: .user, content: "Test message")]
        let request = try service.buildRequest(messages: messages, systemPrompt: nil)

        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let contents = try #require(json["contents"] as? [[String: Any]])
        let parts = try #require(contents[0]["parts"] as? [[String: Any]])

        #expect(parts.count == 1)
        #expect(parts[0]["text"] as? String == "Test message")
    }
}
