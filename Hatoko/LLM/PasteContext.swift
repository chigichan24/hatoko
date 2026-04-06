import Cocoa

struct PasteContext: Sendable, Equatable {
    static let displayIcon = "\u{1f4ce}"

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

    static func buildSystemPrompt(
        base: String,
        context: PasteContext?,
        screenContext: ScreenContext? = nil,
        language: InstructionLanguage = .english
    ) -> String {
        var prompt = base

        if let context {
            switch language {
            case .english:
                prompt += """

                    \nThe user has provided the following reference text as context:
                    <context>
                    \(context.text)
                    </context>
                    Use this context to understand what the user is referring to. \
                    Generate text that is relevant to this context.
                    """
            case .japanese:
                prompt += """

                    \nユーザーが以下の参照テキストをコンテキストとして提供しています:
                    <context>
                    \(context.text)
                    </context>
                    このコンテキストを参考にして、関連するテキストを生成してください。
                    """
            }
        }

        if let screenContext {
            let formatted = screenContext.formatted()
            if !formatted.isEmpty {
                switch language {
                case .english:
                    prompt += """

                        \nThe following is what the user is currently looking at on their screen:
                        \(formatted)
                        Use this screen context to understand the user's current working environment.
                        """
                case .japanese:
                    prompt += """

                        \n以下はユーザーが現在画面上で見ている内容です:
                        \(formatted)
                        この画面コンテキストを参考にして、ユーザーの作業環境を理解してください。
                        """
                }
            }
        }

        return prompt
    }
}
