import Cocoa
import SwiftUI

@preconcurrency @MainActor
final class ChatWindowController {

    private var window: NSPanel?
    private var messages: [ChatMessage] = []
    private var isLoading = false
    private var inputText = ""
    private var onUseText: (@Sendable (String) -> Void)?
    private var onSendMessage: (@Sendable (String) -> Void)?
    private var onCancel: (@Sendable () -> Void)?

    nonisolated func show(
        initialPrompt: String,
        initialResponse: String,
        at origin: NSPoint,
        onUse: @escaping @Sendable (String) -> Void,
        onSend: @escaping @Sendable (String) -> Void,
        onCancel: @escaping @Sendable () -> Void
    ) {
        MainActor.assumeIsolated {
            self.messages = [
                ChatMessage(role: .user, text: initialPrompt),
                ChatMessage(role: .assistant, text: initialResponse),
            ]
            self.isLoading = false
            self.inputText = ""
            self.onUseText = onUse
            self.onSendMessage = onSend
            self.onCancel = onCancel
            self.updateWindow(at: origin)
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

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: hostingView.fittingSize),
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
