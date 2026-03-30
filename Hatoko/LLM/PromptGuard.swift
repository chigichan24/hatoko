struct PromptGuard: Sendable {

    static let maxPromptLength = 2000
    static let maxChatMessageLength = 1000

    enum ValidationResult: Sendable, Equatable {
        case valid(String)
        case tooLong(length: Int, limit: Int)
        case empty
    }

    static func validate(_ input: String, maxLength: Int = maxPromptLength) -> ValidationResult {
        precondition(maxLength > 0, "maxLength must be positive")
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .empty
        }
        if trimmed.count > maxLength {
            return .tooLong(length: trimmed.count, limit: maxLength)
        }
        return .valid(trimmed)
    }
}
