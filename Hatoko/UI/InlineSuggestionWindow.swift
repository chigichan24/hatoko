import Cocoa
import SwiftUI

/// Manages the inline LLM suggestion popup near the cursor.
///
/// Marked `@preconcurrency @MainActor` because all NSWindow operations require the
/// main thread. Public methods are `nonisolated` with `MainActor.assumeIsolated`
/// because they are called from IMKInputController (which always runs on main thread)
/// but cannot be statically proven to be MainActor-isolated.
@preconcurrency @MainActor
final class InlineSuggestionWindow {

    private var window: NSWindow?

    nonisolated func show(suggestion: String, cursorRect: NSRect) {
        MainActor.assumeIsolated {
            showImpl(view: InlineSuggestionView(suggestion: suggestion), cursorRect: cursorRect)
        }
    }

    nonisolated func showLoading(cursorRect: NSRect) {
        MainActor.assumeIsolated {
            showImpl(view: InlineSuggestionView(suggestion: nil), cursorRect: cursorRect)
        }
    }

    nonisolated func hide() {
        MainActor.assumeIsolated {
            window?.orderOut(nil)
            window = nil
        }
    }

    nonisolated var isVisible: Bool {
        MainActor.assumeIsolated {
            window?.isVisible ?? false
        }
    }

    private func showImpl(view: InlineSuggestionView, cursorRect: NSRect) {
        hide()

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame.size = hostingView.fittingSize

        let size = hostingView.fittingSize
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
        panel.contentView = hostingView
        panel.orderFront(nil)

        window = panel
    }
}
