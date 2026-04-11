import Cocoa
@preconcurrency import InputMethodKit
import KanaKanjiConverterModuleWithDefaultDictionary

/// macOS IME input controller.
///
/// ## Concurrency Safety
/// IMKInputController is always instantiated and called on the main thread by the
/// Input Method Kit framework. All mutable state (`composingText`, `inputMode`, etc.)
/// is only accessed from these main-thread callbacks. `@unchecked Sendable` is required
/// solely to allow capturing `self` in `Task {}` closures for async LLM calls, where
/// we immediately bounce back to `MainActor.run {}` before touching any state.
@objc(HatokoInputController)
final class HatokoInputController: IMKInputController, @unchecked Sendable {

    static let noReplacementRange = NSRange(location: NSNotFound, length: NSNotFound)
    static let hankakuToZenkakuMap: [Character: Character] = ["-": "ー", "[": "「", "]": "」", ".": "。", ",": "、", "~": "〜", "!": "！", "?": "？"]
    var inputMode: InputMode = .japanese
    var composingText = ComposingText()
    var japaneseInputState: JapaneseInputState = .composing
    let conversionService = ConversionService()

    // LLM prompt state
    var promptBuffer = ""
    var pasteContext: PasteContext?
    /// The input mode that was active before entering LLM prompt mode.
    var llmBaseMode: LLMBaseMode = .japanese
    var llmSuggestion: String?
    let inlineSuggestionWindow = InlineSuggestionWindow()
    let chatWindowController = ChatWindowController()
    var lastCursorRect: NSRect = .zero
    /// Text waiting to be committed after the host app regains focus from the chat window.
    private var pendingChatText: String?
    /// Process-wide rate limiters shared across all input controller instances
    /// to protect the LLM API from excessive requests.
    static let inlineRateLimiter = RateLimiter()
    static let chatRateLimiter = RateLimiter()
    static let dangerousReadController = DangerousReadModeController()

    func makeConvertOptions(leftSideContext: String? = nil) -> ConvertRequestOptions {
        let dir = applicationSupportDirectory()
        let zenzaiMode = MainActor.assumeIsolated {
            resolveZenzaiMode(leftSideContext: leftSideContext)
        }
        return ConvertRequestOptions(
            N_best: 9,
            requireJapanesePrediction: .disabled,
            requireEnglishPrediction: .disabled,
            keyboardLanguage: .ja_JP,
            learningType: .nothing,
            memoryDirectoryURL: dir,
            sharedContainerURL: dir,
            textReplacer: .empty,
            specialCandidateProviders: nil,
            zenzaiMode: zenzaiMode,
            metadata: .init(
                versionString: "Hatoko \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")"
            )
        )
    }

    @MainActor
    private func resolveZenzaiMode(leftSideContext: String?) -> ConvertRequestOptions.ZenzaiMode {
        guard let modelURL = ZenzaiModelManager.shared.modelFileURL,
              UserDefaults.standard.bool(forKey: ZenzaiModelManager.enabledKey) else {
            return .off
        }
        let inferenceLimit = ZenzaiModelManager.storedInferenceLimit()
        return .on(
            weight: modelURL,
            inferenceLimit: inferenceLimit,
            requestRichCandidates: false,
            personalizationMode: nil,
            versionDependentMode: .v3(.init(leftSideContext: leftSideContext))
        )
    }

    private func applicationSupportDirectory() -> URL {
        guard let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Application Support directory is unavailable")
        }
        let dir = base.appending(path: "Hatoko", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            NSLog("[Hatoko] Failed to create application support directory: \(error)")
        }
        return dir
    }

    // MARK: - IMKInputController Overrides
    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
    }

    override func activateServer(_ sender: Any!) {
        NSLog("[Hatoko] activateServer called")
        super.activateServer(sender)
        resetComposition()
        if let client = sender as? (any IMKTextInput) {
            client.overrideKeyboard(withKeyboardNamed: "com.apple.keylayout.US")
            if let text = pendingChatText {
                pendingChatText = nil
                commitText(text, to: client)
            }
        }
    }

    override func deactivateServer(_ sender: Any!) {
        // Don't cancel LLM mode if the chat window is active — transient
        // deactivate/activate cycles from InputMethodKit would close it.
        if !chatWindowController.isVisible {
            let client = (sender as? (any IMKTextInput)) ?? self.client()
            cancelLLMMode(client: client)
        }
        commitCurrentText(sender)
        super.deactivateServer(sender)
    }

    override func setValue(_ value: Any!, forTag tag: Int, client sender: Any!) {
        guard let value = value as? String else { return }
        if chatWindowController.isVisible {
            // Preserve LLM state during transient IME reactivation
            super.setValue(value, forTag: tag, client: sender)
            return
        }
        let client = (sender as? (any IMKTextInput)) ?? self.client()
        cancelLLMMode(client: client)
        commitCurrentText(sender)
        inputMode = InputMode(modeIdentifier: value)
        super.setValue(value, forTag: tag, client: sender)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event else { return false }

        // Only handle keyDown events
        guard event.type == .keyDown else { return false }

        guard let client = (sender as? (any IMKTextInput)) ?? self.client() else {
            NSLog("[Hatoko] handle: no client available")
            return false
        }

        NSLog("[Hatoko] handle: keyCode=%d chars=%@ mode=%@", event.keyCode, event.characters ?? "nil", "\(inputMode)")

        // Open settings with ⌘,
        if isCommandComma(event: event) {
            MainActor.assumeIsolated {
                SettingsWindowController.shared.showSettings()
            }
            return true
        }

        // Handle chat window interactions (Stage 2)
        if chatWindowController.isVisible {
            return handleChatInput(event: event, client: client)
        }
        // Handle inline suggestion interactions (Stage 1)
        if inlineSuggestionWindow.isVisible {
            return handleInlineSuggestionInput(event: event, client: client)
        }
        // Handle LLM prompt input
        if inputMode == .llmPrompt {
            return handlePromptInput(event: event, client: client)
        }
        // Handle keyboard shortcuts (Ctrl+Shift+D, Ctrl+Space)
        if let result = handleKeyboardShortcuts(event: event, client: client) {
            return result
        }

        if inputMode == .roman { return false }
        return handleJapaneseInput(event: event, client: client)
    }

    override func menu() -> NSMenu! {
        let menu = NSMenu(title: "Hatoko")
        let settingsItem = NSMenuItem(title: L10n.Settings.menuItem, action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        return menu
    }

    @objc private func openSettings() {
        MainActor.assumeIsolated {
            SettingsWindowController.shared.showSettings()
        }
    }

    override func commitComposition(_ sender: Any!) {
        let client = (sender as? (any IMKTextInput)) ?? self.client()
        cancelLLMMode(client: client)
        commitCurrentText(sender)
        super.commitComposition(sender)
    }

    // MARK: - LLM Mode Trigger
    func isCtrlSpace(event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return event.keyCode == KeyCode.space && modifiers.contains(.control)
    }

    private func isCtrlShiftD(event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return event.keyCode == KeyCode.d
            && modifiers.contains(.control)
            && modifiers.contains(.shift)
    }

    private func handleKeyboardShortcuts(event: NSEvent, client: any IMKTextInput) -> Bool? {
        if isCtrlShiftD(event: event) {
            Self.dangerousReadController.toggleSession()
            return true
        }
        if isCtrlSpace(event: event) {
            guard LLMBackend.current.isEnabled else { NSSound.beep(); return true }
            activateLLMMode(client: client)
            return true
        }
        return nil
    }

    private func isCommandComma(event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return event.keyCode == KeyCode.comma
            && modifiers.contains(.command)
            && modifiers.subtracting([.command, .function]).isEmpty
    }

    func cancelLLMMode(client: (any IMKTextInput)? = nil) {
        guard inputMode == .llmPrompt || inlineSuggestionWindow.isVisible || chatWindowController.isVisible else { return }
        inlineSuggestionWindow.hide()
        chatWindowController.hide()
        resetComposition()
        resetLLMState()
        if let client { clearMarkedText(client: client) }
    }

    func resetLLMState() {
        inputMode = llmBaseMode.inputMode
        promptBuffer = ""
        llmSuggestion = nil
        pasteContext = nil
    }

    // MARK: - Inline Suggestion Handling (Stage 1)

    private func handleInlineSuggestionInput(event: NSEvent, client: any IMKTextInput) -> Bool {
        switch event.keyCode {
        case KeyCode.enter:
            // Accept suggestion
            if let suggestion = llmSuggestion {
                commitText(suggestion, to: client)
            }
            inlineSuggestionWindow.hide()
            resetLLMState()
            return true
        case KeyCode.escape:
            // Cancel
            cancelLLMMode(client: client)
            return true
        case KeyCode.tab:
            transitionToChat(client: client)
            return true
        default:
            return true
        }
    }

    // MARK: - Chat Window (Stage 2)

    private func transitionToChat(client: any IMKTextInput) {
        guard let suggestion = llmSuggestion else { return }
        let prompt = promptBuffer
        // IMKTextInput is not Sendable, but this closure runs on the main thread
        // where the client was originally provided by InputMethodKit.
        nonisolated(unsafe) let capturedClient = client

        inlineSuggestionWindow.hide()

        chatWindowController.show(configuration: .init(
            initialPrompt: prompt,
            initialResponse: suggestion,
            pasteContext: pasteContext,
            cursorRect: lastCursorRect,
            onUse: { [weak self] text in
                self?.acceptChatText(text, client: capturedClient)
            },
            onSend: { [weak self] chatHistory in
                self?.sendChatMessage(chatHistory: chatHistory)
            },
            onCancel: { [weak self] in
                self?.cancelLLMMode()
            }
        ))
    }

    private func handleChatInput(event: NSEvent, client: any IMKTextInput) -> Bool {
        if event.keyCode == KeyCode.escape {
            cancelLLMMode(client: client)
            return true
        }
        // Chat window is key (KeyablePanel) and handles its own input
        return false
    }

    private func acceptChatText(_ text: String, client: any IMKTextInput) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        pendingChatText = text
        chatWindowController.hide()
        resetLLMState()
    }

    static func buildLLMMessages(from chatHistory: [ChatMessage]) -> [LLMMessage] {
        chatHistory.suffix(PromptGuard.maxChatHistoryMessages)
            .drop(while: { $0.role == .assistant })
            .map { chatMessage in
                let role: LLMMessage.Role = switch chatMessage.role {
                case .user: .user
                case .assistant: .assistant
                }
                return LLMMessage(role: role, content: chatMessage.text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
    }

    func validateChatMessage(_ text: String) -> Bool {
        switch PromptGuard.validate(text, maxLength: PromptGuard.maxChatMessageLength) {
        case .valid: return true
        case .tooLong:
            chatWindowController.addAssistantMessage(L10n.Error.tooLong)
            return false
        case .empty: return false
        }
    }

    // MARK: - Japanese Input Handling

    private func handleJapaneseInput(event: NSEvent, client: any IMKTextInput) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if !modifiers.subtracting([.shift, .function, .numericPad]).isEmpty {
            return false
        }

        let isShift = modifiers.contains(.shift)

        switch event.keyCode {
        case KeyCode.enter:
            return handleEnter(client: client)
        case KeyCode.backspace:
            return handleBackspace(client: client)
        case KeyCode.escape:
            return handleEscape(client: client)
        case KeyCode.space:
            return handleSpace(client: client, reverse: isShift)
        case KeyCode.arrowDown, KeyCode.arrowUp:
            guard japaneseInputState.isConverting else { return false }
            return cycleCandidate(reverse: event.keyCode == KeyCode.arrowUp, client: client)
        default:
            return handleCharacterInput(event: event, client: client)
        }
    }

    private func handleEnter(client: any IMKTextInput) -> Bool {
        if let candidate = japaneseInputState.selectedCandidate {
            confirmCandidate(candidate, client: client)
            return true
        }
        guard !composingText.convertTarget.isEmpty else { return false }
        commitText(composingText.convertTarget, to: client)
        resetComposition()
        return true
    }

    private func handleBackspace(client: any IMKTextInput) -> Bool {
        guard !composingText.convertTarget.isEmpty else { return false }
        if japaneseInputState.isConverting {
            japaneseInputState = .composing
            updateMarkedText(composingText.convertTarget, client: client)
            return true
        }
        composingText.deleteBackwardFromCursorPosition(count: 1)
        if composingText.convertTarget.isEmpty {
            resetComposition()
            clearMarkedText(client: client)
        } else {
            updateMarkedText(composingText.convertTarget, client: client)
        }
        return true
    }

    private func handleEscape(client: any IMKTextInput) -> Bool {
        guard !composingText.convertTarget.isEmpty else { return false }
        if japaneseInputState.isConverting {
            japaneseInputState = .composing
            updateMarkedText(composingText.convertTarget, client: client)
            return true
        }
        resetComposition()
        clearMarkedText(client: client)
        return true
    }

    private func handleSpace(client: any IMKTextInput, reverse: Bool) -> Bool {
        switch japaneseInputState {
        case .composing:
            guard !composingText.convertTarget.isEmpty else { return false }
            let candidates = conversionService.requestCandidates(
                composingText: composingText,
                options: makeConvertOptions()
            ).mainResults
            guard let first = candidates.first else { return true }
            japaneseInputState = .converting(candidates: candidates, selectedIndex: 0)
            updateMarkedText(first.text, style: .thick, client: client)
            return true
        case .converting:
            return cycleCandidate(reverse: reverse, client: client)
        }
    }

    private func cycleCandidate(reverse: Bool, client: any IMKTextInput) -> Bool {
        japaneseInputState = japaneseInputState.cycled(reverse: reverse)
        // cycled() already asserts if called in composing state.
        // This guard handles the Release-build fallback gracefully.
        guard let candidate = japaneseInputState.selectedCandidate else { return false }
        updateMarkedText(candidate.text, style: .thick, client: client)
        return true
    }

    private func handleCharacterInput(event: NSEvent, client: any IMKTextInput) -> Bool {
        guard let characters = event.characters, !characters.isEmpty else {
            return false
        }

        if let candidate = japaneseInputState.selectedCandidate {
            confirmCandidate(candidate, client: client)
        }

        if insertCharactersIntoComposition(characters) != nil {
            if !composingText.convertTarget.isEmpty {
                commitText(composingText.convertTarget, to: client)
                resetComposition()
            }
            return false
        }

        updateMarkedText(composingText.convertTarget, client: client)
        return true
    }

    // MARK: - Shared Composition Helpers

    /// Inserts characters into composingText using kana conversion rules.
    /// Returns the first character that couldn't be classified (non-letter,
    /// non-mapped), or nil if all characters were successfully inserted.
    func insertCharactersIntoComposition(_ characters: String) -> Character? {
        for char in characters {
            if let mapped = Self.hankakuToZenkakuMap[char] {
                composingText.insertAtCursorPosition(String(mapped), inputStyle: .direct)
            } else if char.isASCII, char.isLetter {
                composingText.insertAtCursorPosition(String(char), inputStyle: .roman2kana)
            } else {
                return char
            }
        }
        return nil
    }

    // MARK: - Client Communication

    private func confirmCandidate(_ candidate: Candidate, client: any IMKTextInput) {
        commitText(candidate.text, to: client)
        composingText.prefixComplete(composingCount: candidate.composingCount)
        resetComposition()
    }

    func commitText(_ text: String, to client: any IMKTextInput) {
        client.insertText(text, replacementRange: Self.noReplacementRange)
    }

    func clearMarkedText(client: any IMKTextInput) {
        client.setMarkedText(
            "",
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: Self.noReplacementRange
        )
    }

    private func updateMarkedText(
        _ text: String,
        style: NSUnderlineStyle = .single,
        client: any IMKTextInput
    ) {
        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .underlineStyle: style.rawValue,
                .foregroundColor: NSColor.textColor,
            ]
        )
        client.setMarkedText(
            attributed,
            selectionRange: NSRange(location: text.utf16.count, length: 0),
            replacementRange: Self.noReplacementRange
        )
    }

    func cursorRect(client: any IMKTextInput) -> NSRect {
        var rect = NSRect.zero
        client.attributes(forCharacterIndex: 0, lineHeightRectangle: &rect)
        return rect
    }

    // MARK: - State Management
    private func commitCurrentText(_ sender: Any?) {
        guard !composingText.convertTarget.isEmpty else { return }
        guard let client = (sender as? (any IMKTextInput)) ?? self.client() else {
            NSLog("[Hatoko] Warning: Could not commit composing text - no IMKTextInput client available")
            resetComposition()
            return
        }
        commitText(japaneseInputState.selectedCandidate?.text ?? composingText.convertTarget, to: client)
        resetComposition()
    }

    func resetComposition() {
        composingText = ComposingText()
        japaneseInputState = .composing
        conversionService.stopComposition()
    }
}
