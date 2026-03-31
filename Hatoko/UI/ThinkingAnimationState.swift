import Foundation
import Observation

/// Testable state machine for the thinking/reveal typewriter animation.
///
/// Drives the animation by advancing one step per `tick()` call.
/// Each tick returns the interval to wait before the next tick,
/// allowing the caller (SwiftUI `.task`) to control pacing.
@Observable
@MainActor
final class ThinkingAnimationState {

    private(set) var displayedText = ""
    private(set) var showCursor = true
    private(set) var isComplete = false

    private var mode: Mode = .thinking
    private var step: Step = .typing
    private var target = ""
    private var targetChars: [Character] = []
    private var charIndex = 0
    private var waitTicks = 0
    private var phraseIterator: ShuffledPhraseIterator

    private static let phrases = [
        "構成を考えています",
        "言い回しを調整中",
        "もう少しで書けそう",
        "いい表現を探しています",
        "下書きを推敲中",
        "文脈を整理しています",
        "ちょっと待ってくださいね",
        "もうすぐまとまります",
        "表現を練っています",
        "最後の仕上げ中",
    ]

    init() {
        phraseIterator = ShuffledPhraseIterator(phraseCount: Self.phrases.count)
        setTarget(Self.phrases[phraseIterator.next()])
    }

    // MARK: - Public API

    func receiveSuggestion(_ text: String) {
        mode = .revealing
        if displayedText.isEmpty {
            setTarget(text)
            charIndex = 0
            step = .typing
        } else {
            step = .erasing
            setTarget(text)
        }
    }

    /// Advance one animation step. Returns the interval to wait before the next call.
    func tick() -> TimeInterval {
        switch step {
        case .typing: return tickTyping()
        case .erasing: return tickErasing()
        case .waitingToErase: return tickWaiting(then: .erasing)
        case .waitingToType: return tickWaiting(then: .typing)
        }
    }

    func toggleCursor() {
        showCursor.toggle()
    }

    private func setTarget(_ text: String) {
        target = text
        targetChars = Array(text)
    }
}

// MARK: - Types

extension ThinkingAnimationState {

    enum Mode { case thinking, revealing }
    enum Step { case typing, erasing, waitingToErase, waitingToType }

    struct ShuffledPhraseIterator {
        private var order: [Int]
        private var index = 0

        init(phraseCount: Int) {
            precondition(phraseCount > 0, "ShuffledPhraseIterator requires at least one element")
            order = Array(0..<phraseCount).shuffled()
        }

        mutating func next() -> Int {
            let result = order[index]
            index += 1
            if index >= order.count {
                order.shuffle()
                index = 0
            }
            return result
        }
    }
}

// MARK: - Tick Handlers

extension ThinkingAnimationState {

    private func tickTyping() -> TimeInterval {
        guard charIndex < targetChars.count else {
            return finishTyping()
        }
        displayedText.append(targetChars[charIndex])
        charIndex += 1
        return mode == .revealing ? Timing.revealInterval(for: targetChars.count) : Timing.typingInterval
    }

    private func finishTyping() -> TimeInterval {
        if mode == .revealing {
            showCursor = false
            isComplete = true
            return 0
        }
        step = .waitingToErase
        waitTicks = Timing.pauseAfterTypeTicks
        return Timing.tickBase
    }

    private func tickErasing() -> TimeInterval {
        guard !displayedText.isEmpty else {
            return finishErasing()
        }
        displayedText.removeLast()
        return Timing.erasingInterval
    }

    private func finishErasing() -> TimeInterval {
        if mode == .revealing {
            charIndex = 0
            step = .typing
            return Timing.pauseBeforeReveal
        }
        setTarget(Self.phrases[phraseIterator.next()])
        charIndex = 0
        step = .waitingToType
        waitTicks = Timing.pauseAfterEraseTicks
        return Timing.tickBase
    }

    private func tickWaiting(then nextStep: Step) -> TimeInterval {
        waitTicks -= 1
        if waitTicks <= 0 {
            step = nextStep
        }
        return Timing.tickBase
    }
}

// MARK: - Timing Constants

extension ThinkingAnimationState {

    enum Timing {
        static let typingInterval: TimeInterval = 0.06
        static let erasingInterval: TimeInterval = 0.03
        static let cursorBlinkInterval: TimeInterval = 0.53
        static let tickBase: TimeInterval = 0.05
        static let pauseBeforeReveal: TimeInterval = 0.15
        static let pauseAfterTypeTicks = 16   // ~0.8s at tickBase
        static let pauseAfterEraseTicks = 6   // ~0.3s at tickBase
        static let fastRevealThreshold = 500

        static func revealInterval(for length: Int) -> TimeInterval {
            length > fastRevealThreshold ? 0.005 : 0.02
        }
    }
}
