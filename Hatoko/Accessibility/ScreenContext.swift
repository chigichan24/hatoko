import Foundation

struct ScreenContext: Sendable, Equatable {

    let appName: String?
    let windowTitle: String?
    let focusedText: String?
    let selectedText: String?
    let capturedAt: Date

    init(
        appName: String?,
        windowTitle: String?,
        focusedText: String?,
        selectedText: String?,
        capturedAt: Date = Date()
    ) {
        self.appName = appName
        self.windowTitle = Self.truncateShort(windowTitle)
        self.focusedText = Self.truncate(focusedText)
        self.selectedText = Self.truncate(selectedText)
        self.capturedAt = capturedAt
    }

    func formatted() -> String {
        var lines: [String] = []
        if let appName {
            lines.append("Application: \(appName)")
        }
        if let windowTitle {
            lines.append("Window: \(windowTitle)")
        }
        if let selectedText {
            lines.append("Selected text: \(selectedText)")
        }
        if let focusedText {
            lines.append("Focused text: \(focusedText)")
        }
        guard !lines.isEmpty else { return "" }
        let body = lines.joined(separator: "\n")
        return "<screen_context>\n\(body)\n</screen_context>"
    }

    private static let maxShortFieldLength = 500

    private static func truncate(_ text: String?) -> String? {
        guard let text, !text.isEmpty else { return nil }
        return String(text.prefix(PromptGuard.maxScreenContextLength))
    }

    private static func truncateShort(_ text: String?) -> String? {
        guard let text, !text.isEmpty else { return nil }
        return String(text.prefix(maxShortFieldLength))
    }
}
