struct LLMMessage: Sendable, Equatable {
    enum Role: String, Sendable {
        case user
        case assistant
    }

    let role: Role
    let content: String
}

protocol LLMService: Sendable {
    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String
}
