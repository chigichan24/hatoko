enum LLMBaseMode: Sendable, Equatable {
    case japanese
    case roman

    init(from inputMode: InputMode) {
        switch inputMode {
        case .japanese, .llmPrompt: self = .japanese
        case .roman: self = .roman
        }
    }

    var toggled: LLMBaseMode {
        switch self {
        case .japanese: .roman
        case .roman: .japanese
        }
    }

    var inputMode: InputMode {
        switch self {
        case .japanese: .japanese
        case .roman: .roman
        }
    }
}
