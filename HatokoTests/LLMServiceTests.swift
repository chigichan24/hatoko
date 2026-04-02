import Foundation
import Testing

@testable import Hatoko

@Suite
struct LLMBackendTests {

    @Test
    func disabledBackendThrowsOnCreateService() {
        #expect(throws: LLMBackendError.self) {
            try LLMBackend.disabled.createService()
        }
    }

    @Test
    func disabledRawValueRoundTrip() {
        let backend = LLMBackend(rawValue: "disabled")
        #expect(backend == .disabled)
    }

    @Test
    func disabledIsNotEnabled() {
        #expect(!LLMBackend.disabled.isEnabled)
    }

    @Test
    func claudeAPIIsEnabled() {
        #expect(LLMBackend.claudeAPI.isEnabled)
    }

    @Test
    func claudeCLIIsEnabled() {
        #expect(LLMBackend.claudeCLI.isEnabled)
    }
}

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
struct ClaudeCLIServiceTests {

    @Test
    func buildPromptFormatsUserContent() {
        let service = ClaudeCLIService()
        let messages = [LLMMessage(role: .user, content: "What is 2+2?")]
        let prompt = service.buildPrompt(messages: messages)

        #expect(prompt == "What is 2+2?")
    }

    @Test
    func buildPromptLabelsAssistantMessages() {
        let service = ClaudeCLIService()
        let messages = [LLMMessage(role: .assistant, content: "The answer is 4.")]
        let prompt = service.buildPrompt(messages: messages)

        #expect(prompt.contains("[ASSISTANT]\nThe answer is 4."))
    }

    @Test
    func buildPromptWithEmptyMessages() {
        let service = ClaudeCLIService()
        let prompt = service.buildPrompt(messages: [])

        #expect(prompt == "")
    }

    @Test
    func buildPromptMultiTurnConversation() {
        let service = ClaudeCLIService()
        let messages = [
            LLMMessage(role: .user, content: "Hello"),
            LLMMessage(role: .assistant, content: "Hi there"),
            LLMMessage(role: .user, content: "Make it formal"),
        ]
        let prompt = service.buildPrompt(messages: messages)

        #expect(prompt.contains("Hello"))
        #expect(prompt.contains("[ASSISTANT]\nHi there"))
        #expect(prompt.contains("Make it formal"))
    }

    @Test
    func buildArgumentsIncludesSystemPrompt() {
        let service = ClaudeCLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: "Be helpful.")

        #expect(args.contains("-p"))
        #expect(args.contains("Hello"))
        #expect(args.contains("--system-prompt"))
        #expect(args.contains("Be helpful."))
    }

    @Test
    func buildArgumentsOmitsSystemPromptWhenNil() {
        let service = ClaudeCLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: nil)

        #expect(args.contains("-p"))
        #expect(args.contains("Hello"))
        #expect(!args.contains("--system-prompt"))
    }
}

@Suite
struct OpenAICLIServiceTests {

    @Test
    func buildArgumentsBasicPrompt() {
        let service = OpenAICLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: nil)

        #expect(args.contains("api"))
        #expect(args.contains("chat.completions.create"))
        #expect(args.contains("-m"))
        #expect(args.contains("gpt-4o"))
        #expect(args.contains("Hello"))
    }

    @Test
    func buildArgumentsWithSystemPrompt() {
        let service = OpenAICLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: "Be helpful.")

        #expect(args.contains("-g"))
        #expect(args.contains("system"))
        #expect(args.contains("Be helpful."))
        #expect(args.contains("Hello"))
    }
}

@Suite
struct GeminiCLIServiceTests {

    @Test
    func buildArgumentsBasicPrompt() {
        let service = GeminiCLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: nil)

        #expect(args.contains("-p"))
        #expect(args.contains("Hello"))
        #expect(!args.contains("--system-prompt"))
    }

    @Test
    func buildArgumentsWithSystemPrompt() {
        let service = GeminiCLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: "Be helpful.")

        #expect(args.contains("-p"))
        #expect(args.contains("Hello"))
        #expect(args.contains("--system-prompt"))
        #expect(args.contains("Be helpful."))
    }
}
