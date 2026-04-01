import Testing

@testable import Hatoko

@Suite
struct BuildLLMMessagesTests {

    @Test
    func normalConversation() {
        let history = [
            ChatMessage(role: .user, text: "Hello"),
            ChatMessage(role: .assistant, text: "Hi"),
            ChatMessage(role: .user, text: "Make it formal"),
        ]
        let result = HatokoInputController.buildLLMMessages(from: history)
        #expect(result.count == 3)
        #expect(result[0].role == .user)
        #expect(result[0].content == "Hello")
        #expect(result[1].role == .assistant)
        #expect(result[2].role == .user)
        #expect(result[2].content == "Make it formal")
    }

    @Test
    func dropsLeadingAssistantMessages() {
        let history = [
            ChatMessage(role: .assistant, text: "stale"),
            ChatMessage(role: .assistant, text: "also stale"),
            ChatMessage(role: .user, text: "Hello"),
            ChatMessage(role: .assistant, text: "Hi"),
        ]
        let result = HatokoInputController.buildLLMMessages(from: history)
        #expect(result.count == 2)
        #expect(result[0].role == .user)
        #expect(result[0].content == "Hello")
    }

    @Test
    func truncatesLongHistory() {
        var history: [ChatMessage] = []
        for i in 0..<30 {
            let role: ChatMessage.ChatRole = i.isMultiple(of: 2) ? .user : .assistant
            history.append(ChatMessage(role: role, text: "msg\(i)"))
        }
        let result = HatokoInputController.buildLLMMessages(from: history)
        #expect(result.count <= PromptGuard.maxChatHistoryMessages)
    }

    @Test
    func emptyHistory() {
        let result = HatokoInputController.buildLLMMessages(from: [])
        #expect(result.isEmpty)
    }

    @Test
    func allAssistantMessages() {
        let history = [
            ChatMessage(role: .assistant, text: "a"),
            ChatMessage(role: .assistant, text: "b"),
        ]
        let result = HatokoInputController.buildLLMMessages(from: history)
        #expect(result.isEmpty)
    }

    @Test
    func trimsWhitespace() {
        let history = [
            ChatMessage(role: .user, text: "  hello  "),
        ]
        let result = HatokoInputController.buildLLMMessages(from: history)
        #expect(result[0].content == "hello")
    }
}
