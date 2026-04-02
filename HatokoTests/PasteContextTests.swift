import Foundation
import Testing

@testable import Hatoko

@Suite
struct PasteContextTests {

    @Test
    func buildSystemPromptWithNilContextReturnsBase() {
        let base = "You are a helpful assistant."
        let result = PasteContext.buildSystemPrompt(base: base, context: nil)
        #expect(result == base)
    }

    @Test
    func buildSystemPromptWithContextInjectsText() {
        let base = "You are a helpful assistant."
        let context = PasteContext.create(text: "clipboard content")
        let result = PasteContext.buildSystemPrompt(base: base, context: context)
        #expect(result.contains("clipboard content"))
    }

    @Test
    func buildSystemPromptPreservesBaseAtStart() {
        let base = "You are a helpful assistant."
        let context = PasteContext.create(text: "some text")
        let result = PasteContext.buildSystemPrompt(base: base, context: context)
        #expect(result.hasPrefix(base))
    }

    @Test
    func buildSystemPromptWrapsContextWithDelimiters() {
        let base = "Base prompt"
        let context = PasteContext.create(text: "important reference")
        let result = PasteContext.buildSystemPrompt(base: base, context: context)
        #expect(result.contains("---\nimportant reference\n---"))
    }

    @Test
    func createReturnsNilForEmptyText() {
        #expect(PasteContext.create(text: "") == nil)
    }

    @Test
    func createReturnsNilForWhitespaceOnly() {
        #expect(PasteContext.create(text: "   \n\t  ") == nil)
    }

    @Test
    func createTrimsWhitespace() {
        let context = PasteContext.create(text: "  hello  ")
        #expect(context?.text == "hello")
    }

    @Test
    func createPreservesInternalWhitespace() {
        let context = PasteContext.create(text: "  hello world  ")
        #expect(context?.text == "hello world")
    }

    @Test
    func createPreservesInternalNewlines() {
        let context = PasteContext.create(text: "\nline1\nline2\n")
        #expect(context?.text == "line1\nline2")
    }

    @Test
    func buildSystemPromptWithDelimiterInContext() {
        let base = "Base prompt"
        let context = PasteContext.create(text: "before\n---\ninjected\n---\nafter")
        let result = PasteContext.buildSystemPrompt(base: base, context: context)
        #expect(result.hasPrefix(base))
        #expect(result.contains("before\n---\ninjected\n---\nafter"))
    }

    @Test
    func createTruncatesLongText() {
        let longText = String(repeating: "a", count: PromptGuard.maxPasteContextLength + 500)
        let context = PasteContext.create(text: longText)
        #expect(context?.text.count == PromptGuard.maxPasteContextLength)
    }
}
