import Foundation
import Testing

@testable import Hatoko

@Suite
struct SystemPromptProviderTests {

    @Test
    func inlineEnglishContainsExpectedContent() {
        let text = SystemPromptProvider.inline.text(for: .english)
        #expect(text.contains("IME text-generation assistant"))
    }

    @Test
    func inlineJapaneseContainsExpectedContent() {
        let text = SystemPromptProvider.inline.text(for: .japanese)
        #expect(text.contains("IMEのテキスト生成アシスタント"))
    }

    @Test
    func chatEnglishContainsExpectedContent() {
        let text = SystemPromptProvider.chat.text(for: .english)
        #expect(text.contains("multi-turn conversation"))
    }

    @Test
    func chatJapaneseContainsExpectedContent() {
        let text = SystemPromptProvider.chat.text(for: .japanese)
        #expect(text.contains("複数ターンの会話"))
    }

    @Test
    func inlineEnglishAndJapaneseDiffer() {
        #expect(SystemPromptProvider.inline.text(for: .english)
            != SystemPromptProvider.inline.text(for: .japanese))
    }

    @Test
    func chatEnglishAndJapaneseDiffer() {
        #expect(SystemPromptProvider.chat.text(for: .english)
            != SystemPromptProvider.chat.text(for: .japanese))
    }
}
