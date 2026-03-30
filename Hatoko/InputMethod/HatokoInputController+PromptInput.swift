import Cocoa
@preconcurrency import InputMethodKit
import KanaKanjiConverterModuleWithDefaultDictionary

extension HatokoInputController {

    // MARK: - LLM Mode Activation

    func activateLLMMode(client: any IMKTextInput) {
        // Commit any in-progress Japanese text first
        if !composingText.convertTarget.isEmpty {
            commitText(composingText.convertTarget, to: client)
            resetComposition()
        }
        llmBaseMode = LLMBaseMode(from: inputMode)
        inputMode = .llmPrompt
        promptBuffer = ""
        updatePromptMarkedText(client: client)
    }

    // MARK: - Prompt Input Handling

    func handlePromptInput(event: NSEvent, client: any IMKTextInput) -> Bool {
        // Toggle base input mode with Ctrl+Space while in LLM prompt
        if isCtrlSpace(event: event) {
            toggleLLMBaseMode(client: client)
            return true
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if !modifiers.subtracting(.shift).isEmpty {
            return false
        }

        let isShift = modifiers.contains(.shift)

        switch event.keyCode {
        case KeyCode.enter:
            return handlePromptEnter(client: client)
        case KeyCode.backspace:
            return handlePromptBackspace(client: client)
        case KeyCode.escape:
            return handlePromptEscape(client: client)
        case KeyCode.space:
            return handlePromptSpace(client: client, reverse: isShift)
        case KeyCode.arrowDown, KeyCode.arrowUp:
            guard japaneseInputState.isConverting else { return false }
            return promptCycleCandidate(reverse: event.keyCode == KeyCode.arrowUp, client: client)
        default:
            return handlePromptCharacter(event: event, client: client)
        }
    }

    private func handlePromptEnter(client: any IMKTextInput) -> Bool {
        // (a) If converting or composing, flush to promptBuffer
        if japaneseInputState.isConverting || !composingText.convertTarget.isEmpty {
            flushCompositionToPromptBuffer()
            updatePromptMarkedText(client: client)
            return true
        }

        // (b) Nothing being composed — submit the full prompt to LLM
        guard !promptBuffer.isEmpty else { return true }

        clearMarkedText(client: client)
        let cursorOrigin = cursorScreenPosition(client: client)
        lastCursorOrigin = cursorOrigin
        inlineSuggestionWindow.showLoading(at: cursorOrigin)
        let prompt = promptBuffer
        requestLLMGeneration(prompt: prompt, cursorOrigin: cursorOrigin)
        return true
    }

    private func handlePromptBackspace(client: any IMKTextInput) -> Bool {
        // (a) If converting, return to composing state
        if japaneseInputState.isConverting {
            japaneseInputState = .composing
            updatePromptMarkedText(client: client)
            return true
        }

        // (b) If composing, delete backward
        if !composingText.convertTarget.isEmpty {
            composingText.deleteBackwardFromCursorPosition(count: 1)
            if composingText.convertTarget.isEmpty {
                resetComposition()
            }
            updatePromptMarkedText(client: client)
            return true
        }

        // (c) If promptBuffer has content, remove last character
        if !promptBuffer.isEmpty {
            promptBuffer.removeLast()
            updatePromptMarkedText(client: client)
            return true
        }

        // (d) Both empty — cancel LLM mode
        cancelLLMMode(client: client)
        return true
    }

    private func handlePromptEscape(client: any IMKTextInput) -> Bool {
        // (a) If converting, return to composing state
        if japaneseInputState.isConverting {
            japaneseInputState = .composing
            updatePromptMarkedText(client: client)
            return true
        }

        // (b) If composing, cancel composition but stay in LLM mode
        if !composingText.convertTarget.isEmpty {
            resetComposition()
            updatePromptMarkedText(client: client)
            return true
        }

        // (c) Nothing composing — cancel LLM mode entirely
        cancelLLMMode(client: client)
        return true
    }

    private func handlePromptCharacter(event: NSEvent, client: any IMKTextInput) -> Bool {
        guard let characters = event.characters, !characters.isEmpty else {
            return false
        }

        // Roman base mode: append characters directly without kana conversion
        if llmBaseMode == .roman {
            promptBuffer.append(characters)
            updatePromptMarkedText(client: client)
            return true
        }

        // Japanese base mode: use romaji-to-kana conversion pipeline
        if let candidate = japaneseInputState.selectedCandidate {
            promptConfirmCandidate(candidate)
        }

        // In prompt mode, non-letter characters (digits, symbols) are captured
        // into promptBuffer rather than passed through to the system.
        if let remaining = insertCharactersIntoComposition(characters) {
            if !composingText.convertTarget.isEmpty {
                promptBuffer.append(composingText.convertTarget)
                resetComposition()
            }
            promptBuffer.append(remaining)
            updatePromptMarkedText(client: client)
            return true
        }

        updatePromptMarkedText(client: client)
        return true
    }

    private func handlePromptSpace(client: any IMKTextInput, reverse: Bool) -> Bool {
        // Roman base mode: space is always a literal space
        if llmBaseMode == .roman {
            promptBuffer.append(" ")
            updatePromptMarkedText(client: client)
            return true
        }

        switch japaneseInputState {
        case .composing:
            guard !composingText.convertTarget.isEmpty else {
                promptBuffer.append(" ")
                updatePromptMarkedText(client: client)
                return true
            }
            let candidates = conversionService.requestCandidates(
                composingText: composingText,
                options: convertOptions
            ).mainResults
            guard !candidates.isEmpty else { return true }
            japaneseInputState = .converting(candidates: candidates, selectedIndex: 0)
            updatePromptMarkedText(client: client)
            return true
        case .converting:
            return promptCycleCandidate(reverse: reverse, client: client)
        }
    }

    private func promptCycleCandidate(reverse: Bool, client: any IMKTextInput) -> Bool {
        japaneseInputState = japaneseInputState.cycled(reverse: reverse)
        // cycled() already asserts if called in composing state.
        // This guard handles the Release-build fallback gracefully.
        guard japaneseInputState.selectedCandidate != nil else { return false }
        updatePromptMarkedText(client: client)
        return true
    }

    private func toggleLLMBaseMode(client: any IMKTextInput) {
        flushCompositionToPromptBuffer()
        llmBaseMode = llmBaseMode.toggled
        updatePromptMarkedText(client: client)
    }

    /// Flushes any in-progress composition (converting or composing) into promptBuffer.
    private func flushCompositionToPromptBuffer() {
        if let candidate = japaneseInputState.selectedCandidate {
            promptConfirmCandidate(candidate)
        } else if !composingText.convertTarget.isEmpty {
            promptBuffer.append(composingText.convertTarget)
            resetComposition()
        }
    }

    private func promptConfirmCandidate(_ candidate: Candidate) {
        promptBuffer.append(candidate.text)
        composingText.prefixComplete(composingCount: candidate.composingCount)
        resetComposition()
    }

    private func updatePromptMarkedText(client: any IMKTextInput) {
        let prefix = llmBaseMode == .japanese ? "✦ あ " : "✦ A "
        let result = NSMutableAttributedString()

        // Prefix + promptBuffer: pink, single underline
        let bufferPart = prefix + promptBuffer
        result.append(NSAttributedString(
            string: bufferPart,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: NSColor.systemPink,
            ]
        ))

        // Composing/converting part
        if let candidate = japaneseInputState.selectedCandidate {
            result.append(NSAttributedString(
                string: candidate.text,
                attributes: [
                    .underlineStyle: NSUnderlineStyle.thick.rawValue,
                    .foregroundColor: NSColor.systemPink,
                ]
            ))
        } else if !composingText.convertTarget.isEmpty {
            result.append(NSAttributedString(
                string: composingText.convertTarget,
                attributes: [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: NSColor.systemPink,
                ]
            ))
        }

        client.setMarkedText(
            result,
            selectionRange: NSRange(location: result.length, length: 0),
            replacementRange: Self.noReplacementRange
        )
    }
}
