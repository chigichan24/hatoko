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
        let context = PasteContext(text: "clipboard content")
        let result = PasteContext.buildSystemPrompt(base: base, context: context)
        #expect(result.contains("clipboard content"))
    }

    @Test
    func buildSystemPromptPreservesBaseAtStart() {
        let base = "You are a helpful assistant."
        let context = PasteContext(text: "some text")
        let result = PasteContext.buildSystemPrompt(base: base, context: context)
        #expect(result.hasPrefix(base))
    }

    @Test
    func buildSystemPromptContainsContextText() {
        let base = "Base prompt"
        let context = PasteContext(text: "important reference")
        let result = PasteContext.buildSystemPrompt(base: base, context: context)
        #expect(result.contains("important reference"))
    }
}
