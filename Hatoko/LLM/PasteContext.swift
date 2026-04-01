import Cocoa

struct PasteContext: Sendable, Equatable {
    let text: String

    static func fromPasteboard() -> PasteContext? {
        guard let text = NSPasteboard.general.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let trimmed = String(text.prefix(PromptGuard.maxPasteContextLength))
        return PasteContext(text: trimmed)
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
