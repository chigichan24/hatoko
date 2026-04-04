import SwiftUI

/// Displays a typewriter animation while waiting for LLM response.
///
/// Uses `ThinkingAnimationState` (an `@Observable` state machine) for
/// all animation logic. The view's `.task` drives the animation loop
/// via `state.tick()`, which automatically cancels when the view disappears.
struct ThinkingAnimationView: View {

    let suggestion: String?
    var onRevealComplete: () -> Void = {}

    @State private var state = ThinkingAnimationState()

    var body: some View {
        HStack(spacing: 0) {
            Text(state.displayedText)
                .font(.body)
                .lineSpacing(4)
            if state.showCursor {
                Text("|")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(suggestion.map { L10n.Thinking.suggestionAccessibility($0) } ?? L10n.Thinking.generatingAccessibility)
        .task(id: state.isComplete) {
            guard !state.isComplete else { return }
            await runAnimation()
        }
        .task {
            await blinkCursor()
        }
        .onChange(of: suggestion) { _, newValue in
            if let text = newValue {
                state.receiveSuggestion(text)
            }
        }
    }

    private func runAnimation() async {
        while !state.isComplete {
            let interval = state.tick()
            guard interval > 0 else { continue }
            do {
                try await Task.sleep(for: .seconds(interval))
            } catch {
                return
            }
        }
        onRevealComplete()
    }

    private func blinkCursor() async {
        while !state.isComplete {
            do {
                try await Task.sleep(for: .seconds(ThinkingAnimationState.Timing.cursorBlinkInterval))
            } catch {
                return
            }
            if !state.isComplete {
                state.toggleCursor()
            }
        }
    }
}
