import Cocoa

struct PasteContext: Sendable, Equatable {
    let text: String

    private init(text: String) {
        self.text = text
    }

    static func create(text: String) -> PasteContext? {
        assert(PromptGuard.maxPasteContextLength > 0)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let truncated = String(trimmed.prefix(PromptGuard.maxPasteContextLength))
        return PasteContext(text: truncated)
    }

    static func fromPasteboard() -> PasteContext? {
        guard let text = NSPasteboard.general.string(forType: .string) else {
            return nil
        }
        return create(text: text)
    }

    static func buildSystemPrompt(base: String, context: PasteContext?) -> String {
        guard let context else { return base }
        return """
            \(base)

            The user has provided the following reference text as context:
            ---
            \(context.text)
            ---
            Use this context to understand what the user is referring to. \
            Generate text that is relevant to this context.
            """
    }
}
