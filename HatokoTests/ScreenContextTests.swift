import Foundation
import Testing

@testable import Hatoko

@Suite
struct ScreenContextTests {

    @Test
    func formattedWithAllFields() {
        let context = ScreenContext(
            appName: "Safari",
            windowTitle: "GitHub",
            focusedText: "some code",
            selectedText: "selected"
        )
        let result = context.formatted()
        #expect(result.contains("<screen_context>"))
        #expect(result.contains("</screen_context>"))
        #expect(result.contains("Application: Safari"))
        #expect(result.contains("Window: GitHub"))
        #expect(result.contains("Focused text: some code"))
        #expect(result.contains("Selected text: selected"))
    }

    @Test
    func formattedWithOnlyAppName() {
        let context = ScreenContext(
            appName: "Terminal",
            windowTitle: nil,
            focusedText: nil,
            selectedText: nil
        )
        let result = context.formatted()
        #expect(result.contains("Application: Terminal"))
        #expect(!result.contains("Window:"))
        #expect(!result.contains("Focused text:"))
        #expect(!result.contains("Selected text:"))
    }

    @Test
    func formattedWithAllNilFieldsReturnsEmpty() {
        let context = ScreenContext(
            appName: nil,
            windowTitle: nil,
            focusedText: nil,
            selectedText: nil
        )
        #expect(context.formatted().isEmpty)
    }

    @Test
    func truncatesLongFocusedText() {
        let longText = String(repeating: "a", count: PromptGuard.maxScreenContextLength + 500)
        let context = ScreenContext(
            appName: nil,
            windowTitle: nil,
            focusedText: longText,
            selectedText: nil
        )
        #expect(context.focusedText?.count == PromptGuard.maxScreenContextLength)
    }

    @Test
    func truncatesLongSelectedText() {
        let longText = String(repeating: "b", count: PromptGuard.maxScreenContextLength + 100)
        let context = ScreenContext(
            appName: nil,
            windowTitle: nil,
            focusedText: nil,
            selectedText: longText
        )
        #expect(context.selectedText?.count == PromptGuard.maxScreenContextLength)
    }

    @Test
    func emptyStringTreatedAsNil() {
        let context = ScreenContext(
            appName: "App",
            windowTitle: nil,
            focusedText: "",
            selectedText: ""
        )
        #expect(context.focusedText == nil)
        #expect(context.selectedText == nil)
    }

    @Test
    func formattedOutputOrderIsCorrect() throws {
        let context = ScreenContext(
            appName: "Xcode",
            windowTitle: "Project",
            focusedText: "code",
            selectedText: "sel"
        )
        let result = context.formatted()
        let appRange = try #require(result.range(of: "Application:"))
        let windowRange = try #require(result.range(of: "Window:"))
        let selectedRange = try #require(result.range(of: "Selected text:"))
        let focusedRange = try #require(result.range(of: "Focused text:"))
        // Order: app → window → selected → focused
        #expect(appRange.lowerBound < windowRange.lowerBound)
        #expect(windowRange.lowerBound < selectedRange.lowerBound)
        #expect(selectedRange.lowerBound < focusedRange.lowerBound)
    }
}
