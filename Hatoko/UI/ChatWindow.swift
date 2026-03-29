import Cocoa
import SwiftUI

/// Manages the ephemeral chat window for LLM refinement.
///
/// Same isolation strategy as InlineSuggestionWindow: `@preconcurrency @MainActor`
/// with `nonisolated` + `MainActor.assumeIsolated` for methods called from
/// IMKInputController's main-thread callbacks.
@preconcurrency @MainActor
final class ChatWindowController {

    private var window: NSPanel?
    private var messages: [ChatMessage] = []
    private var isLoading = false
    private var inputText = ""
    struct Configuration: Sendable {
        let initialPrompt: String
        let initialResponse: String
        let origin: NSPoint
        let onUse: @Sendable (String) -> Void
        let onSend: @Sendable (String) -> Void
        let onCancel: @Sendable () -> Void
    }

    private var onUseText: (@Sendable (String) -> Void)?
    private var onSendMessage: (@Sendable (String) -> Void)?
    private var onCancel: (@Sendable () -> Void)?

    nonisolated func show(configuration: Configuration) {
        MainActor.assumeIsolated {
            self.messages = [
                ChatMessage(role: .user, text: configuration.initialPrompt),
                ChatMessage(role: .assistant, text: configuration.initialResponse),
            ]
            self.isLoading = false
            self.inputText = ""
            self.onUseText = configuration.onUse
            self.onSendMessage = configuration.onSend
            self.onCancel = configuration.onCancel
            self.updateWindow(at: configuration.origin)
        }
    }

    nonisolated func addAssistantMessage(_ text: String) {
        MainActor.assumeIsolated {
            self.isLoading = false
            self.messages.append(ChatMessage(role: .assistant, text: text))
            self.refreshContent()
        }
    }

    nonisolated func showLoading() {
        MainActor.assumeIsolated {
            self.isLoading = true
            self.refreshContent()
        }
    }

    nonisolated func hide() {
        MainActor.assumeIsolated {
            self.window?.orderOut(nil)
            self.window = nil
            self.messages = []
            self.onUseText = nil
            self.onSendMessage = nil
            self.onCancel = nil
        }
    }

    nonisolated var isVisible: Bool {
        MainActor.assumeIsolated {
            self.window?.isVisible ?? false
        }
    }

    private func updateWindow(at origin: NSPoint) {
        let chatView = ChatView(
            messages: messages,
            isLoading: isLoading,
            inputText: Binding(
                get: { [weak self] in self?.inputText ?? "" },
                set: { [weak self] in self?.inputText = $0 }
            ),
            onSend: { [weak self] in self?.handleSend() },
            onUse: { [weak self] text in self?.handleUse(text) },
            onCancel: { [weak self] in self?.handleCancel() }
        )

        let hostingView = NSHostingView(rootView: chatView)
        hostingView.frame.size = hostingView.fittingSize

        let size = hostingView.fittingSize
        let adjustedOrigin = Self.adjustedOrigin(for: size, cursorOrigin: origin)

        let panel = NSPanel(
            contentRect: NSRect(origin: adjustedOrigin, size: size),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentView = hostingView
        panel.orderFront(nil)

        window?.orderOut(nil)
        window = panel
    }

    private static func adjustedOrigin(for size: NSSize, cursorOrigin: NSPoint) -> NSPoint {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(origin: .zero, size: NSSize(width: 1920, height: 1080))

        var x = cursorOrigin.x
        var y = cursorOrigin.y

        // Place below cursor; if not enough space below, place above
        if y - size.height < screenFrame.minY {
            y = cursorOrigin.y + 20
        } else {
            y = cursorOrigin.y - size.height
        }

        // Clamp horizontally
        if x + size.width > screenFrame.maxX {
            x = screenFrame.maxX - size.width
        }
        if x < screenFrame.minX {
            x = screenFrame.minX
        }

        return NSPoint(x: x, y: y)
    }

    private func refreshContent() {
        guard let origin = window?.frame.origin else { return }
        updateWindow(at: origin)
    }

    private func handleSend() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(role: .user, text: text))
        inputText = ""
        isLoading = true
        refreshContent()
        onSendMessage?(text)
    }

    private func handleUse(_ text: String) {
        onUseText?(text)
    }

    private func handleCancel() {
        onCancel?()
    }
}
