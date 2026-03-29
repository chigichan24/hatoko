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

    private enum KeyCode {
        static let enter: UInt16 = 36
        static let backspace: UInt16 = 51
        static let escape: UInt16 = 53
        static let space: UInt16 = 49
        static let tab: UInt16 = 48
    }

    private static let noReplacementRange = NSRange(location: NSNotFound, length: NSNotFound)
    private static let llmSystemPrompt = """
        You are an IME assistant. Generate the text the user is asking for. \
        Respond ONLY with the generated text, no explanations.
        """

    private var inputMode: InputMode = .japanese
    private var composingText = ComposingText()
    private let conversionService = ConversionService()

    // LLM prompt state
    private var promptBuffer = ""
    private var llmSuggestion: String?
    private let inlineSuggestionWindow = InlineSuggestionWindow()
    private let chatWindowController = ChatWindowController()
    private var lastCursorOrigin: NSPoint = .zero

    private lazy var convertOptions: ConvertRequestOptions = {
        let dir = applicationSupportDirectory()
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
            metadata: .init(versionString: "Hatoko \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")")
        )
    }()

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
        }
    }


    override func deactivateServer(_ sender: Any!) {
        cancelLLMMode()
        commitCurrentText(sender)
        super.deactivateServer(sender)
    }

    override func setValue(_ value: Any!, forTag tag: Int, client sender: Any!) {
        guard let value = value as? String else { return }
        cancelLLMMode()
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

        // Check for Ctrl+Space to activate LLM mode
        if isLLMTrigger(event: event) {
            activateLLMMode(client: client)
            return true
        }

        if inputMode == .roman {
            return false
        }

        return handleJapaneseInput(event: event, client: client)
    }

    override func menu() -> NSMenu! {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Hatoko 設定...", action: #selector(openSettings), keyEquivalent: "")
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
        cancelLLMMode()
        commitCurrentText(sender)
        super.commitComposition(sender)
    }

    // MARK: - LLM Mode Trigger

    private func isLLMTrigger(event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return event.keyCode == KeyCode.space && modifiers.contains(.control)
    }

    private func activateLLMMode(client: any IMKTextInput) {
        // Commit any in-progress Japanese text first
        if !composingText.convertTarget.isEmpty {
            commitText(composingText.convertTarget, to: client)
            resetComposition()
        }
        inputMode = .llmPrompt
        promptBuffer = ""
        updatePromptMarkedText(client: client)
    }

    private func cancelLLMMode() {
        if inputMode == .llmPrompt || inlineSuggestionWindow.isVisible || chatWindowController.isVisible {
            inlineSuggestionWindow.hide()
            chatWindowController.hide()
            inputMode = .japanese
            promptBuffer = ""
            llmSuggestion = nil
        }
    }

    // MARK: - Prompt Input Handling

    private func handlePromptInput(event: NSEvent, client: any IMKTextInput) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if !modifiers.subtracting(.shift).isEmpty {
            return false
        }

        switch event.keyCode {
        case KeyCode.enter:
            return handlePromptSubmit(client: client)
        case KeyCode.backspace:
            return handlePromptBackspace(client: client)
        case KeyCode.escape:
            return handlePromptEscape(client: client)
        default:
            return handlePromptCharacter(event: event, client: client)
        }
    }

    private func handlePromptSubmit(client: any IMKTextInput) -> Bool {
        guard !promptBuffer.isEmpty else { return true }

        // Clear marked text
        clearMarkedText(client: client)

        // Show loading indicator at cursor position
        let cursorOrigin = cursorScreenPosition(client: client)
        lastCursorOrigin = cursorOrigin
        inlineSuggestionWindow.showLoading(at: cursorOrigin)

        let prompt = promptBuffer

        // Request LLM generation
        requestLLMGeneration(prompt: prompt, cursorOrigin: cursorOrigin)

        return true
    }

    private func handlePromptBackspace(client: any IMKTextInput) -> Bool {
        if promptBuffer.isEmpty {
            cancelLLMMode()
            clearMarkedText(client: client)
            return true
        }
        promptBuffer.removeLast()
        updatePromptMarkedText(client: client)
        return true
    }

    private func handlePromptEscape(client: any IMKTextInput) -> Bool {
        cancelLLMMode()
        clearMarkedText(client: client)
        return true
    }

    private func handlePromptCharacter(event: NSEvent, client: any IMKTextInput) -> Bool {
        guard let characters = event.characters, !characters.isEmpty else {
            return false
        }
        promptBuffer.append(characters)
        updatePromptMarkedText(client: client)
        return true
    }

    private func updatePromptMarkedText(client: any IMKTextInput) {
        let display = "✦ \(promptBuffer)"
        let attributed = NSAttributedString(
            string: display,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: NSColor.systemPink,
            ]
        )
        client.setMarkedText(
            attributed,
            selectionRange: NSRange(location: display.utf16.count, length: 0),
            replacementRange: Self.noReplacementRange
        )
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
            inputMode = .japanese
            promptBuffer = ""
            llmSuggestion = nil
            return true
        case KeyCode.escape:
            // Cancel
            cancelLLMMode()
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
            origin: lastCursorOrigin,
            onUse: { [weak self] text in
                self?.acceptChatText(text, client: capturedClient)
            },
            onSend: { [weak self] message in
                self?.sendChatMessage(message, previousPrompt: prompt)
            },
            onCancel: { [weak self] in
                self?.cancelLLMMode()
            }
        ))
    }

    private func handleChatInput(event: NSEvent, client: any IMKTextInput) -> Bool {
        if event.keyCode == KeyCode.escape {
            cancelLLMMode()
            return true
        }
        // Let the chat window handle other keys via its own TextField
        return false
    }

    private func acceptChatText(_ text: String, client: any IMKTextInput) {
        chatWindowController.hide()
        commitText(text, to: client)
        inputMode = .japanese
        promptBuffer = ""
        llmSuggestion = nil
    }

    private func sendChatMessage(_ message: String, previousPrompt: String) {
        let service: any LLMService
        do {
            service = try LLMBackend.current.createService()
        } catch {
            NSLog("[Hatoko] LLM backend configuration error: \(error)")
            chatWindowController.addAssistantMessage("設定エラー: バックエンドの構成を確認してください。")
            return
        }

        // Build conversation history from chat messages
        var llmMessages = [
            LLMMessage(role: .user, content: previousPrompt),
        ]
        if let suggestion = llmSuggestion {
            llmMessages.append(LLMMessage(role: .assistant, content: suggestion))
        }
        llmMessages.append(LLMMessage(role: .user, content: message))

        Task {
            do {
                let result = try await service.generate(
                    messages: llmMessages,
                    systemPrompt: Self.llmSystemPrompt
                )
                await MainActor.run {
                    self.llmSuggestion = result
                    self.chatWindowController.addAssistantMessage(result)
                }
            } catch {
                NSLog("[Hatoko] LLM chat generation failed: \(error)")
                await MainActor.run {
                    self.chatWindowController.addAssistantMessage("エラーが発生しました。もう一度お試しください。")
                }
            }
        }
    }

    // MARK: - Japanese Input Handling

    private func handleJapaneseInput(event: NSEvent, client: any IMKTextInput) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if !modifiers.subtracting(.shift).isEmpty {
            return false
        }

        switch event.keyCode {
        case KeyCode.enter:
            return handleEnter(client: client)
        case KeyCode.backspace:
            return handleBackspace(client: client)
        case KeyCode.escape:
            return handleEscape(client: client)
        case KeyCode.space:
            return handleSpace(client: client)
        default:
            return handleCharacterInput(event: event, client: client)
        }
    }

    private func handleEnter(client: any IMKTextInput) -> Bool {
        guard !composingText.convertTarget.isEmpty else { return false }
        commitText(composingText.convertTarget, to: client)
        resetComposition()
        return true
    }

    private func handleBackspace(client: any IMKTextInput) -> Bool {
        guard !composingText.convertTarget.isEmpty else { return false }
        composingText.deleteBackwardFromCursorPosition(count: 1)
        if composingText.convertTarget.isEmpty {
            resetComposition()
            clearMarkedText(client: client)
        } else {
            updateMarkedText(client: client)
        }
        return true
    }

    private func handleEscape(client: any IMKTextInput) -> Bool {
        guard !composingText.convertTarget.isEmpty else { return false }
        resetComposition()
        clearMarkedText(client: client)
        return true
    }

    private func handleSpace(client: any IMKTextInput) -> Bool {
        guard !composingText.convertTarget.isEmpty else { return false }
        let result = conversionService.requestCandidates(
            composingText: composingText,
            options: convertOptions
        )
        if let topCandidate = result.mainResults.first {
            commitText(topCandidate.text, to: client)
            composingText.prefixComplete(composingCount: topCandidate.composingCount)
            resetComposition()
        }
        return true
    }

    private func handleCharacterInput(event: NSEvent, client: any IMKTextInput) -> Bool {
        guard let characters = event.characters, !characters.isEmpty else {
            return false
        }

        for char in characters {
            guard char.isASCII, char.isLetter || char == "-" else {
                if !composingText.convertTarget.isEmpty {
                    commitText(composingText.convertTarget, to: client)
                    resetComposition()
                }
                return false
            }
            composingText.insertAtCursorPosition(String(char), inputStyle: .roman2kana)
        }

        updateMarkedText(client: client)
        return true
    }

    // MARK: - Client Communication

    private func commitText(_ text: String, to client: any IMKTextInput) {
        client.insertText(text, replacementRange: Self.noReplacementRange)
    }

    private func clearMarkedText(client: any IMKTextInput) {
        client.setMarkedText(
            "",
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: Self.noReplacementRange
        )
    }

    private func updateMarkedText(client: any IMKTextInput) {
        let text = composingText.convertTarget
        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: NSColor.textColor,
            ]
        )
        client.setMarkedText(
            attributed,
            selectionRange: NSRange(location: text.utf16.count, length: 0),
            replacementRange: Self.noReplacementRange
        )
    }

    private func cursorScreenPosition(client: any IMKTextInput) -> NSPoint {
        var rect = NSRect.zero
        client.attributes(forCharacterIndex: 0, lineHeightRectangle: &rect)
        return NSPoint(x: rect.origin.x, y: rect.origin.y - 4)
    }

    // MARK: - LLM Generation

    private func requestLLMGeneration(prompt: String, cursorOrigin: NSPoint) {
        let service: any LLMService
        do {
            service = try LLMBackend.current.createService()
        } catch {
            NSLog("[Hatoko] LLM backend configuration error: \(error)")
            return
        }

        Task {
            do {
                let result = try await service.generate(
                    messages: [LLMMessage(role: .user, content: prompt)],
                    systemPrompt: Self.llmSystemPrompt
                )
                await MainActor.run {
                    self.llmSuggestion = result
                    self.inlineSuggestionWindow.show(suggestion: result, at: cursorOrigin)
                }
            } catch {
                NSLog("[Hatoko] LLM generation failed: \(error)")
                await MainActor.run {
                    self.inlineSuggestionWindow.hide()
                    self.inputMode = .japanese
                }
            }
        }
    }

    // MARK: - State Management

    private func commitCurrentText(_ sender: Any?) {
        guard !composingText.convertTarget.isEmpty else { return }
        guard let client = (sender as? (any IMKTextInput)) ?? self.client() else {
            NSLog("[Hatoko] Warning: Could not commit composing text - no IMKTextInput client available")
            resetComposition()
            return
        }
        commitText(composingText.convertTarget, to: client)
        resetComposition()
    }

    private func resetComposition() {
        composingText = ComposingText()
        conversionService.stopComposition()
    }
}
