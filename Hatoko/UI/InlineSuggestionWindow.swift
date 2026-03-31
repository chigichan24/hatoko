import Cocoa
import SwiftUI

/// Manages the inline LLM suggestion popup near the cursor.
///
/// Marked `@preconcurrency @MainActor` because all NSWindow operations require the
/// main thread. Public methods are `nonisolated` with `MainActor.assumeIsolated`
/// because they are called from IMKInputController (which always runs on main thread)
/// but cannot be statically proven to be MainActor-isolated.
///
/// Uses NSHostingController to update rootView without recreating the panel,
/// preserving ThinkingAnimationView's @State across loading → suggestion transitions.
@preconcurrency @MainActor
final class InlineSuggestionWindow {

    private var panel: NSPanel?
    private var hostingController: NSHostingController<InlineSuggestionView>?

    nonisolated func show(suggestion: String, cursorRect: NSRect) {
        MainActor.assumeIsolated {
            updateOrCreate(suggestion: suggestion, cursorRect: cursorRect)
        }
    }

    nonisolated func showLoading(cursorRect: NSRect) {
        MainActor.assumeIsolated {
            updateOrCreate(suggestion: nil, cursorRect: cursorRect)
        }
    }

    nonisolated func hide() {
        MainActor.assumeIsolated {
            panel?.orderOut(nil)
            panel = nil
            hostingController = nil
        }
    }

    nonisolated var isVisible: Bool {
        MainActor.assumeIsolated {
            panel?.isVisible ?? false
        }
    }

    private func updateOrCreate(suggestion: String?, cursorRect: NSRect) {
        let view = InlineSuggestionView(suggestion: suggestion)

        if let hostingController, let panel {
            hostingController.rootView = view
            hostingController.view.layoutSubtreeIfNeeded()
            let size = hostingController.view.fittingSize
            panel.setContentSize(size)
            let origin = WindowPositioning.origin(for: size, cursorRect: cursorRect)
            panel.setFrameOrigin(origin)
            return
        }

        createPanel(view: view, cursorRect: cursorRect)
    }

    private func createPanel(view: InlineSuggestionView, cursorRect: NSRect) {
        let controller = NSHostingController(rootView: view)
        controller.view.layoutSubtreeIfNeeded()
        let size = controller.view.fittingSize
        let origin = WindowPositioning.origin(for: size, cursorRect: cursorRect)

        let newPanel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.level = .popUpMenu
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.contentViewController = controller
        newPanel.orderFront(nil)

        hostingController = controller
        panel = newPanel
    }
}
