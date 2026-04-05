import Foundation
import Testing

@testable import Hatoko

@Suite(.serialized)
struct LLMBackendTests {

    @Test
    func disabledBackendThrowsOnCreateService() async {
        await #expect(throws: LLMBackendError.self) {
            try await LLMBackend.disabled.createService()
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

    @Test
    func openaiAPIIsEnabled() {
        #expect(LLMBackend.openaiAPI.isEnabled)
    }

    @Test
    func openaiCLIIsEnabled() {
        #expect(LLMBackend.openaiCLI.isEnabled)
    }

    @Test
    func geminiAPIIsEnabled() {
        #expect(LLMBackend.geminiAPI.isEnabled)
    }

    @Test
    func geminiCLIIsEnabled() {
        #expect(LLMBackend.geminiCLI.isEnabled)
    }

    @Test
    func rawValueRoundTripForAllCases() {
        for backend in LLMBackend.allCases {
            #expect(LLMBackend(rawValue: backend.rawValue) == backend)
        }
    }

    @Test
    func migrateOldAPIValue() {
        let key = "llm_backend"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        UserDefaults.standard.set("api", forKey: key)
        LLMBackend.migrateIfNeeded()
        #expect(UserDefaults.standard.string(forKey: key) == "claude_api")
    }

    @Test
    func migrateOldCLIValue() {
        let key = "llm_backend"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        UserDefaults.standard.set("cli", forKey: key)
        LLMBackend.migrateIfNeeded()
        #expect(UserDefaults.standard.string(forKey: key) == "claude_cli")
    }

    @Test
    func migrateDoesNotChangeNewValues() {
        let key = "llm_backend"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        UserDefaults.standard.set("openai_api", forKey: key)
        LLMBackend.migrateIfNeeded()
        #expect(UserDefaults.standard.string(forKey: key) == "openai_api")
    }
}

@Suite
struct CLIRunnerTests {

    @Test
    func buildPromptFormatsUserContent() {
        let messages = [LLMMessage(role: .user, content: "What is 2+2?")]
        #expect(CLIRunner.buildPrompt(messages: messages) == "What is 2+2?")
    }

    @Test
    func buildPromptLabelsAssistantMessages() {
        let messages = [LLMMessage(role: .assistant, content: "The answer is 4.")]
        let prompt = CLIRunner.buildPrompt(messages: messages)
        #expect(prompt.contains("[ASSISTANT]\nThe answer is 4."))
    }

    @Test
    func resolveShebangWithEnvNode() throws {
        let script = NSTemporaryDirectory() + "test_shebang_node.sh"
        defer { try? FileManager.default.removeItem(atPath: script) }
        try "#!/usr/bin/env node\nconsole.log('hi');\n".write(toFile: script, atomically: true, encoding: .utf8)
        let result = CLIRunner.resolveShebang(atPath: script)
        #expect(result != nil)
        #expect(result?.interpreterArgs == [])
    }

    @Test
    func resolveShebangWithEnvSAndFlags() throws {
        let script = NSTemporaryDirectory() + "test_shebang_flags.sh"
        defer { try? FileManager.default.removeItem(atPath: script) }
        try "#!/usr/bin/env -S node --no-warnings=DEP0040\nconsole.log('hi');\n"
            .write(toFile: script, atomically: true, encoding: .utf8)
        let result = CLIRunner.resolveShebang(atPath: script)
        #expect(result != nil)
        #expect(result?.interpreterArgs == ["--no-warnings=DEP0040"])
    }

    @Test
    func resolveShebangReturnsNilForBinary() throws {
        let file = NSTemporaryDirectory() + "test_shebang_binary"
        defer { try? FileManager.default.removeItem(atPath: file) }
        try Data([0x00, 0x01, 0x02, 0x03]).write(to: URL(fileURLWithPath: file))
        #expect(CLIRunner.resolveShebang(atPath: file) == nil)
    }

    @Test
    func resolveShebangReturnsNilForNonexistentFile() {
        #expect(CLIRunner.resolveShebang(atPath: "/nonexistent/path") == nil)
    }

    @Test
    func resolveShebangReturnsNilForDirectShebang() throws {
        let script = NSTemporaryDirectory() + "test_shebang_direct.sh"
        defer { try? FileManager.default.removeItem(atPath: script) }
        try "#!/bin/bash\necho hi\n".write(toFile: script, atomically: true, encoding: .utf8)
        #expect(CLIRunner.resolveShebang(atPath: script) == nil)
    }

    @Test
    func resolveShebangReturnsNilForUnknownInterpreter() throws {
        let script = NSTemporaryDirectory() + "test_shebang_unknown.sh"
        defer { try? FileManager.default.removeItem(atPath: script) }
        try "#!/usr/bin/env nonexistent_interpreter_xyz\necho hi\n"
            .write(toFile: script, atomically: true, encoding: .utf8)
        #expect(CLIRunner.resolveShebang(atPath: script) == nil)
    }

    @Test
    func buildPromptWithEmptyMessages() {
        #expect(CLIRunner.buildPrompt(messages: []) == "")
    }

    @Test
    func buildPromptMultiTurnConversation() {
        let messages = [
            LLMMessage(role: .user, content: "Hello"),
            LLMMessage(role: .assistant, content: "Hi there"),
            LLMMessage(role: .user, content: "Make it formal"),
        ]
        let prompt = CLIRunner.buildPrompt(messages: messages)
        #expect(prompt == "Hello\n\n[ASSISTANT]\nHi there\n\nMake it formal")
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
    func buildArgumentsIncludesSystemPrompt() {
        let service = ClaudeCLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: "Be helpful.")
        #expect(args == ["-p", "Hello", "--system-prompt", "Be helpful."])
    }

    @Test
    func buildArgumentsOmitsSystemPromptWhenNil() {
        let service = ClaudeCLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: nil)
        #expect(args == ["-p", "Hello"])
    }
}

@Suite
struct OpenAICLIServiceTests {

    @Test
    func buildArgumentsBasicPrompt() {
        let service = OpenAICLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: nil)
        #expect(args == ["api", "chat.completions.create", "-m", "gpt-4o", "-g", "user", "Hello"])
    }

    @Test
    func buildArgumentsWithSystemPrompt() {
        let service = OpenAICLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: "Be helpful.")
        #expect(args == ["api", "chat.completions.create", "-m", "gpt-4o",
                         "-g", "system", "Be helpful.", "-g", "user", "Hello"])
    }
}

@Suite
struct GeminiCLIServiceTests {

    @Test
    func buildArgumentsBasicPrompt() {
        let service = GeminiCLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: nil)
        #expect(args == ["-p", "Hello"])
    }

    @Test
    func buildArgumentsWithSystemPromptEmbedded() {
        let service = GeminiCLIService()
        let args = service.buildArguments(prompt: "Hello", systemPrompt: "Be helpful.")
        #expect(args == ["-p", "[System Instructions]\nBe helpful.\n\n[User Request]\nHello"])
    }
}
