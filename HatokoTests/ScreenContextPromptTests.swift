import Foundation
import Testing

@testable import Hatoko

@Suite
struct ScreenContextPromptTests {

    @Test
    func buildSystemPromptWithNilScreenContextReturnsUnchanged() {
        let base = "You are a helpful assistant."
        let result = PasteContext.buildSystemPrompt(base: base, context: nil, screenContext: nil)
        #expect(result == base)
    }

    @Test
    func buildSystemPromptWithScreenContextInjectsBlock() {
        let base = "Base prompt"
        let sc = ScreenContext(
            appName: "Safari",
            windowTitle: "GitHub",
            focusedText: nil,
            selectedText: "hello"
        )
        let result = PasteContext.buildSystemPrompt(base: base, context: nil, screenContext: sc)
        #expect(result.contains("<screen_context>"))
        #expect(result.contains("Application: Safari"))
        #expect(result.contains("Window: GitHub"))
        #expect(result.contains("Selected text: hello"))
    }

    @Test
    func buildSystemPromptPreservesBaseWithScreenContext() {
        let base = "Base prompt"
        let sc = ScreenContext(appName: "App", windowTitle: nil, focusedText: nil, selectedText: nil)
        let result = PasteContext.buildSystemPrompt(base: base, context: nil, screenContext: sc)
        #expect(result.hasPrefix(base))
    }

    @Test
    func buildSystemPromptCombinesPasteAndScreenContext() {
        let base = "Base"
        let paste = PasteContext.create(text: "clipboard text")
        let sc = ScreenContext(appName: "Xcode", windowTitle: nil, focusedText: nil, selectedText: nil)
        let result = PasteContext.buildSystemPrompt(base: base, context: paste, screenContext: sc)
        #expect(result.contains("<context>\nclipboard text\n</context>"))
        #expect(result.contains("<screen_context>"))
        #expect(result.contains("Application: Xcode"))
    }

    @Test
    func buildSystemPromptScreenContextComesAfterPasteContext() throws {
        let base = "Base"
        let paste = PasteContext.create(text: "paste")
        let sc = ScreenContext(appName: "App", windowTitle: nil, focusedText: nil, selectedText: nil)
        let result = PasteContext.buildSystemPrompt(base: base, context: paste, screenContext: sc)
        let pasteRange = try #require(result.range(of: "<context>"))
        let screenRange = try #require(result.range(of: "<screen_context>"))
        #expect(pasteRange.lowerBound < screenRange.lowerBound)
    }

    @Test
    func buildSystemPromptScreenContextWithEmptyFormattedIsIgnored() {
        let base = "Base"
        let sc = ScreenContext(appName: nil, windowTitle: nil, focusedText: nil, selectedText: nil)
        let result = PasteContext.buildSystemPrompt(base: base, context: nil, screenContext: sc)
        #expect(result == base)
    }

    @Test
    func buildSystemPromptJapaneseWithScreenContext() {
        let base = "ベース"
        let sc = ScreenContext(appName: "Safari", windowTitle: nil, focusedText: nil, selectedText: nil)
        let result = PasteContext.buildSystemPrompt(
            base: base, context: nil, screenContext: sc, language: .japanese
        )
        #expect(result.contains("以下はユーザーが現在画面上で見ている内容です"))
        #expect(result.contains("Application: Safari"))
    }

    @Test
    func buildSystemPromptJapaneseWithBothContexts() {
        let base = "ベース"
        let paste = PasteContext.create(text: "クリップボード")
        let sc = ScreenContext(appName: "App", windowTitle: nil, focusedText: nil, selectedText: nil)
        let result = PasteContext.buildSystemPrompt(
            base: base, context: paste, screenContext: sc, language: .japanese
        )
        #expect(result.contains("ユーザーが以下の参照テキストをコンテキストとして提供しています"))
        #expect(result.contains("以下はユーザーが現在画面上で見ている内容です"))
    }

    @Test
    func defaultScreenContextParameterIsNil() {
        let base = "Base"
        let withDefault = PasteContext.buildSystemPrompt(base: base, context: nil)
        let withExplicitNil = PasteContext.buildSystemPrompt(base: base, context: nil, screenContext: nil)
        #expect(withDefault == withExplicitNil)
    }
}
