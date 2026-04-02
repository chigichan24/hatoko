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
        #expect(result.contains("<context>\nimportant reference\n</context>"))
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
        let contextText = "before\n---\ninjected\n---\nafter"
        let context = PasteContext.create(text: contextText)
        let result = PasteContext.buildSystemPrompt(base: base, context: context)
        #expect(result.hasPrefix(base))
        // XML tags clearly delimit context even when content contains ---
        #expect(result.contains("<context>\n\(contextText)\n</context>"))
    }

    @Test
    func buildSystemPromptPreservesClosingTagInContext() {
        // Context text containing </context> is passed through verbatim.
        // LLM prompts are not programmatically parsed, so sanitization
        // would alter user content without meaningful safety benefit.
        let base = "Base"
        let contextText = "code: </context> end"
        let context = PasteContext.create(text: contextText)
        let result = PasteContext.buildSystemPrompt(base: base, context: context)
        #expect(result.contains(contextText))
    }

    @Test
    func createTruncatesLongText() {
        let longText = String(repeating: "a", count: PromptGuard.maxPasteContextLength + 500)
        let context = PasteContext.create(text: longText)
        #expect(context?.text.count == PromptGuard.maxPasteContextLength)
    }
}
