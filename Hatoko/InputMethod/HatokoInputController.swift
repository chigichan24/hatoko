import Cocoa
import InputMethodKit
import KanaKanjiConverterModuleWithDefaultDictionary

@objc(HatokoInputController)
final class HatokoInputController: IMKInputController {

    private var inputMode: InputMode = .japanese
    private var composingText = ComposingText()
    private let conversionService = ConversionService()

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
        super.activateServer(sender)
        resetComposition()
    }

    override func deactivateServer(_ sender: Any!) {
        commitCurrentText(sender)
        super.deactivateServer(sender)
    }

    override func setValue(_ value: Any!, forTag tag: Int, client sender: Any!) {
        guard let value = value as? String else { return }
        commitCurrentText(sender)
        if value.hasSuffix("Roman") {
            inputMode = .roman
        } else {
            inputMode = .japanese
        }
        super.setValue(value, forTag: tag, client: sender)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, let client = sender as? (any IMKTextInput) else {
            return false
        }

        if inputMode == .roman {
            return false
        }

        return handleJapaneseInput(event: event, client: client)
    }

    override func commitComposition(_ sender: Any!) {
        commitCurrentText(sender)
        super.commitComposition(sender)
    }

    // MARK: - Japanese Input Handling

    private func handleJapaneseInput(event: NSEvent, client: any IMKTextInput) -> Bool {
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Ignore events with modifier keys (except shift)
        if !modifiers.subtracting(.shift).isEmpty {
            return false
        }

        switch keyCode {
        case 36: // Enter
            return handleEnter(client: client)
        case 51: // Backspace
            return handleBackspace(client: client)
        case 53: // Escape
            return handleEscape(client: client)
        case 49: // Space
            return handleSpace(client: client)
        default:
            return handleCharacterInput(event: event, client: client)
        }
    }

    private func handleEnter(client: any IMKTextInput) -> Bool {
        guard !composingText.convertTarget.isEmpty else { return false }
        let text = composingText.convertTarget
        client.insertText(text, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        resetComposition()
        return true
    }

    private func handleBackspace(client: any IMKTextInput) -> Bool {
        guard !composingText.convertTarget.isEmpty else { return false }
        composingText.deleteBackwardFromCursorPosition(count: 1)
        if composingText.convertTarget.isEmpty {
            resetComposition()
            client.setMarkedText("", selectionRange: NSRange(location: 0, length: 0), replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        } else {
            updateMarkedText(client: client)
        }
        return true
    }

    private func handleEscape(client: any IMKTextInput) -> Bool {
        guard !composingText.convertTarget.isEmpty else { return false }
        resetComposition()
        client.setMarkedText("", selectionRange: NSRange(location: 0, length: 0), replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        return true
    }

    private func handleSpace(client: any IMKTextInput) -> Bool {
        guard !composingText.convertTarget.isEmpty else { return false }
        let result = conversionService.requestCandidates(
            composingText: composingText,
            options: convertOptions
        )
        if let topCandidate = result.mainResults.first {
            client.insertText(topCandidate.text, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
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
                    // Non-letter while composing: commit current text first
                    let text = composingText.convertTarget
                    client.insertText(text, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
                    resetComposition()
                }
                return false
            }
            composingText.insertAtCursorPosition(String(char), inputStyle: .roman2kana)
        }

        updateMarkedText(client: client)
        return true
    }

    // MARK: - Display

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
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    // MARK: - State Management

    private func commitCurrentText(_ sender: Any?) {
        guard !composingText.convertTarget.isEmpty else { return }
        if let client = sender as? (any IMKTextInput) {
            client.insertText(
                composingText.convertTarget,
                replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
            )
        }
        resetComposition()
    }

    private func resetComposition() {
        composingText = ComposingText()
        conversionService.stopComposition()
    }
}
