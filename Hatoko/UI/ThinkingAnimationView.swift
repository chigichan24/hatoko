import SwiftUI

struct ThinkingAnimationView: View {

    let suggestion: String?
    let onRevealComplete: () -> Void

    @State private var displayedText = ""
    @State private var showCursor = true
    @State private var phase: Phase = .idle
    @State private var phraseOrder: [Int] = []
    @State private var phraseIndex = 0
    @State private var animationTimer: Timer?
    @State private var cursorTimer: Timer?

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

    var body: some View {
        HStack(spacing: 0) {
            Text(displayedText)
                .font(.body)
                .lineSpacing(4)
            if phase != .done {
                Text(showCursor ? "|" : " ")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(suggestion.map { "提案: \($0)" } ?? "提案を生成中")
        .onAppear { start() }
        .onDisappear { stopAllTimers() }
        .onChange(of: suggestion) { _, newValue in
            if let text = newValue {
                startReveal(text)
            }
        }
    }
}

// MARK: - Phase

extension ThinkingAnimationView {

    enum Phase: Equatable {
        case idle
        case typing
        case pauseAfterType
        case erasing
        case pauseAfterErase
        case revealing
        case done
    }
}

// MARK: - Animation Control

extension ThinkingAnimationView {

    private func start() {
        phraseOrder = Array(0..<Self.phrases.count).shuffled()
        phraseIndex = 0
        startCursorBlink()
        if let suggestion {
            startReveal(suggestion)
        } else {
            beginTypingPhrase()
        }
    }

    private func startCursorBlink() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.53, repeats: true) { _ in
            MainActor.assumeIsolated { showCursor.toggle() }
        }
    }

    private func stopAllTimers() {
        animationTimer?.invalidate()
        animationTimer = nil
        cursorTimer?.invalidate()
        cursorTimer = nil
    }

    private func currentPhrase() -> String {
        let index = phraseOrder[phraseIndex % phraseOrder.count]
        return Self.phrases[index]
    }
}

// MARK: - Thinking Loop

extension ThinkingAnimationView {

    private func beginTypingPhrase() {
        phase = .typing
        displayedText = ""
        let phrase = currentPhrase()
        let chars = Array(phrase)
        var charIndex = 0

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { _ in
            MainActor.assumeIsolated {
                guard phase == .typing else { return }
                if charIndex < chars.count {
                    displayedText.append(chars[charIndex])
                    charIndex += 1
                } else {
                    animationTimer?.invalidate()
                    animationTimer = nil
                    phase = .pauseAfterType
                    scheduleNext(.erasePhrase, after: 0.8)
                }
            }
        }
    }

    private func beginErasingPhrase() {
        phase = .erasing

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            MainActor.assumeIsolated {
                guard phase == .erasing else { return }
                if !displayedText.isEmpty {
                    displayedText.removeLast()
                } else {
                    animationTimer?.invalidate()
                    animationTimer = nil
                    phase = .pauseAfterErase
                    advancePhrase()
                    scheduleNext(.typePhrase, after: 0.3)
                }
            }
        }
    }

    private func advancePhrase() {
        phraseIndex += 1
        if phraseIndex >= phraseOrder.count {
            phraseOrder.shuffle()
            phraseIndex = 0
        }
    }
}

// MARK: - Reveal

extension ThinkingAnimationView {

    private func startReveal(_ text: String) {
        animationTimer?.invalidate()
        animationTimer = nil

        if displayedText.isEmpty {
            beginRevealTyping(text)
            return
        }

        phase = .erasing
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            MainActor.assumeIsolated {
                if !displayedText.isEmpty {
                    displayedText.removeLast()
                } else {
                    animationTimer?.invalidate()
                    animationTimer = nil
                    scheduleNext(.revealText(text), after: 0.15)
                }
            }
        }
    }

    private func beginRevealTyping(_ text: String) {
        phase = .revealing
        displayedText = ""
        let chars = Array(text)
        var charIndex = 0
        let interval: TimeInterval = chars.count > 500 ? 0.005 : 0.02

        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            MainActor.assumeIsolated {
                guard phase == .revealing else { return }
                if charIndex < chars.count {
                    displayedText.append(chars[charIndex])
                    charIndex += 1
                } else {
                    animationTimer?.invalidate()
                    animationTimer = nil
                    cursorTimer?.invalidate()
                    cursorTimer = nil
                    phase = .done
                    onRevealComplete()
                }
            }
        }
    }
}

// MARK: - Scheduling

extension ThinkingAnimationView {

    private enum NextAction: Sendable {
        case typePhrase
        case erasePhrase
        case revealText(String)
    }

    private func scheduleNext(_ action: NextAction, after delay: TimeInterval) {
        animationTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [action] _ in
            MainActor.assumeIsolated {
                switch action {
                case .typePhrase: beginTypingPhrase()
                case .erasePhrase: beginErasingPhrase()
                case .revealText(let text): beginRevealTyping(text)
                }
            }
        }
    }
}
