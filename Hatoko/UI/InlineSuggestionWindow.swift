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
/// preserving ThinkingAnimationView's state across loading → suggestion transitions.
@preconcurrency @MainActor
final class InlineSuggestionWindow {

    private struct ActivePanel {
        let panel: NSPanel
        let hostingController: NSHostingController<InlineSuggestionView>
    }

    private var activePanel: ActivePanel?

    nonisolated func show(suggestion: String, cursorRect: NSRect, hasContext: Bool = false) {
        MainActor.assumeIsolated {
            updateOrCreate(suggestion: suggestion, cursorRect: cursorRect, hasContext: hasContext)
        }
    }

    nonisolated func showLoading(cursorRect: NSRect, hasContext: Bool = false) {
        MainActor.assumeIsolated {
            updateOrCreate(suggestion: nil, cursorRect: cursorRect, hasContext: hasContext)
        }
    }

    nonisolated func hide() {
        MainActor.assumeIsolated {
            activePanel?.panel.orderOut(nil)
            activePanel = nil
        }
    }

    nonisolated var isVisible: Bool {
        MainActor.assumeIsolated {
            activePanel?.panel.isVisible ?? false
        }
    }

    private func updateOrCreate(suggestion: String?, cursorRect: NSRect, hasContext: Bool = false) {
        let view = InlineSuggestionView(suggestion: suggestion, hasContext: hasContext)

        if let active = activePanel {
            active.hostingController.rootView = view
            active.hostingController.view.layoutSubtreeIfNeeded()
            let size = active.hostingController.view.fittingSize
            active.panel.setContentSize(size)
            let origin = WindowPositioning.origin(for: size, cursorRect: cursorRect)
            active.panel.setFrameOrigin(origin)
            return
        }

        createPanel(view: view, cursorRect: cursorRect)
    }

    private func createPanel(view: InlineSuggestionView, cursorRect: NSRect) {
        let controller = NSHostingController(rootView: view)
        controller.view.layoutSubtreeIfNeeded()
        let size = controller.view.fittingSize
        let origin = WindowPositioning.origin(for: size, cursorRect: cursorRect)

        let panel = NSPanel(
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
        panel.orderFront(nil)

        activePanel = ActivePanel(panel: panel, hostingController: controller)
    }
}
