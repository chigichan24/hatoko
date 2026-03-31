import Foundation
@testable import Hatoko
import Testing

@Suite
struct ThinkingAnimationStateTests {

    @MainActor
    @Test
    func initialStateStartsTyping() {
        let state = ThinkingAnimationState()
        #expect(state.displayedText == "")
        #expect(state.showCursor == true)
        #expect(state.isComplete == false)
    }

    @MainActor
    @Test
    func tickTypesOneCharacterAtATime() {
        let state = ThinkingAnimationState()
        _ = state.tick()
        #expect(state.displayedText.count == 1)
        _ = state.tick()
        #expect(state.displayedText.count == 2)
    }

    @MainActor
    @Test
    func thinkingLoopTypesAndErases() {
        let state = ThinkingAnimationState()

        // Type until waiting phase (tickBase returned instead of typingInterval)
        var interval: TimeInterval = 0
        repeat {
            interval = state.tick()
        } while interval == ThinkingAnimationState.Timing.typingInterval

        let typedText = state.displayedText
        #expect(!typedText.isEmpty)

        // Should be in waiting phase now (tickBase interval)
        #expect(interval == ThinkingAnimationState.Timing.tickBase)

        // Exhaust wait ticks to transition to erasing
        for _ in 0..<ThinkingAnimationState.Timing.pauseAfterTypeTicks {
            _ = state.tick()
        }

        // Should now be in erasing phase
        let eraseInterval = state.tick()
        #expect(eraseInterval == ThinkingAnimationState.Timing.erasingInterval)
        #expect(state.displayedText.count < typedText.count)
    }

    @MainActor
    @Test
    func receiveSuggestionStartsReveal() {
        let state = ThinkingAnimationState()

        // Type a few characters
        for _ in 0..<3 {
            _ = state.tick()
        }
        #expect(!state.displayedText.isEmpty)

        // Receive suggestion
        state.receiveSuggestion("Hello")

        // Should start erasing
        let interval = state.tick()
        #expect(interval == ThinkingAnimationState.Timing.erasingInterval)
    }

    @MainActor
    @Test
    func revealCompletesWithFullText() {
        let state = ThinkingAnimationState()
        let text = "AB"

        state.receiveSuggestion(text)

        // Tick until complete
        while !state.isComplete {
            _ = state.tick()
        }

        #expect(state.displayedText == text)
        #expect(state.showCursor == false)
        #expect(state.isComplete == true)
    }

    @MainActor
    @Test
    func revealOnEmptyDisplaySkipsErase() {
        let state = ThinkingAnimationState()
        let text = "Test"

        // Receive before any typing
        state.receiveSuggestion(text)

        // Should go directly to typing the real text
        _ = state.tick()
        #expect(state.displayedText == "T")
    }

    @MainActor
    @Test
    func cursorToggle() {
        let state = ThinkingAnimationState()
        #expect(state.showCursor == true)
        state.toggleCursor()
        #expect(state.showCursor == false)
        state.toggleCursor()
        #expect(state.showCursor == true)
    }
}
