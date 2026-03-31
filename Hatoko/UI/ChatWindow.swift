import Cocoa
import SwiftUI

/// A non-activating panel that can still become key window,
/// allowing SwiftUI TextField to receive keyboard focus.
/// Intercepts Escape key directly since IMKInputController.handle()
/// may not receive events when this panel is key.
private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }

    var onEscape: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == KeyCode.escape {
            if let onEscape {
                onEscape()
            } else {
                super.keyDown(with: event)
            }
            return
        }
        super.keyDown(with: event)
    }
}

/// Manages the ephemeral chat window for LLM refinement.
///
/// The chat panel uses `KeyablePanel` (canBecomeKey = true) with
/// `makeKeyAndOrderFront` so that the SwiftUI TextField receives
/// keyboard focus. This causes transient IME deactivation, which
/// is handled by `HatokoInputController.deactivateServer` skipping
/// `cancelLLMMode` when the chat window is visible.
///
/// Public methods are `nonisolated` with `MainActor.assumeIsolated`
/// because they are called from IMKInputController (which always runs
/// on main thread) but cannot be statically proven to be MainActor-isolated.
@preconcurrency @MainActor
final class ChatWindowController {

    private struct ActivePanel {
        let panel: KeyablePanel
        let hostingController: NSHostingController<ChatView>
    }

    private var activePanel: ActivePanel?
    private var messages: [ChatMessage] = []
    private var isLoading = false
    private var inputText = ""
    private var lastCursorRect: NSRect = .zero
    struct Configuration: Sendable {
        let initialPrompt: String
        let initialResponse: String
        let cursorRect: NSRect
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
            self.updateWindow(cursorRect: configuration.cursorRect)
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
            self.activePanel?.panel.orderOut(nil)
            self.activePanel = nil
            self.messages = []
            self.onUseText = nil
            self.onSendMessage = nil
            self.onCancel = nil
        }
    }

    nonisolated var isVisible: Bool {
        MainActor.assumeIsolated {
            self.activePanel?.panel.isVisible ?? false
        }
    }

    // MARK: - Window Management

    private func makeChatView() -> ChatView {
        ChatView(
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
    }

    private func updateWindow(cursorRect: NSRect) {
        lastCursorRect = cursorRect
        let chatView = makeChatView()

        if let active = activePanel, active.panel.isVisible {
            active.hostingController.rootView = chatView
            active.hostingController.view.layoutSubtreeIfNeeded()
            let fitting = active.hostingController.view.fittingSize
            let size = NSSize(
                width: fitting.width,
                height: min(fitting.height, 500)
            )
            active.panel.setContentSize(size)
            let origin = WindowPositioning.origin(for: size, cursorRect: cursorRect)
            active.panel.setFrameOrigin(origin)
            return
        }

        // Clean up stale panel before creating a new one
        activePanel?.panel.orderOut(nil)
        activePanel = nil
        createPanel(chatView: chatView, cursorRect: cursorRect)
    }

    private func createPanel(chatView: ChatView, cursorRect: NSRect) {
        let controller = NSHostingController(rootView: chatView)
        controller.view.layoutSubtreeIfNeeded()
        let fitting = controller.view.fittingSize
        let size = NSSize(
            width: fitting.width,
            height: min(fitting.height, 500)
        )
        let origin = WindowPositioning.origin(for: size, cursorRect: cursorRect)

        let panel = KeyablePanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.contentViewController = controller
        panel.onEscape = { [weak self] in self?.handleCancel() }
        activePanel = ActivePanel(panel: panel, hostingController: controller)
        panel.makeKeyAndOrderFront(nil)

        // Re-measure after the panel is on screen. ScrollView reports near-zero
        // height for fittingSize before the hosting view is attached to a window,
        // so the initial panel size underestimates the message area.
        refreshContent()
    }

    private func refreshContent() {
        updateWindow(cursorRect: lastCursorRect)
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
