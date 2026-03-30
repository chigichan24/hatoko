import Foundation
import Testing

@testable import Hatoko

@Suite
struct PromptGuardTests {

    @Test
    func normalInput() {
        let result = PromptGuard.validate("Hello, world!")
        #expect(result == .valid("Hello, world!"))
    }

    @Test
    func whitespaceOnlyReturnsEmpty() {
        let result = PromptGuard.validate("   \n\t  ")
        #expect(result == .empty)
    }

    @Test
    func trimmingWhitespace() {
        let result = PromptGuard.validate("  hello  ")
        #expect(result == .valid("hello"))
    }

    @Test
    func overMaxPromptLength() {
        let length = PromptGuard.maxPromptLength + 500
        let longString = String(repeating: "a", count: length)
        let result = PromptGuard.validate(longString)
        #expect(result == .tooLong(length: length, limit: PromptGuard.maxPromptLength))
    }

    @Test
    func customMaxLength() {
        let input = String(repeating: "b", count: 11)
        let result = PromptGuard.validate(input, maxLength: 10)
        #expect(result == .tooLong(length: 11, limit: 10))
    }

    @Test
    func exactlyAtLimit() {
        let input = String(repeating: "c", count: PromptGuard.maxPromptLength)
        let result = PromptGuard.validate(input)
        #expect(result == .valid(input))
    }

    @Test
    func limitPlusOne() {
        let input = String(repeating: "d", count: PromptGuard.maxPromptLength + 1)
        let result = PromptGuard.validate(input)
        #expect(result == .tooLong(length: PromptGuard.maxPromptLength + 1, limit: PromptGuard.maxPromptLength))
    }
}
