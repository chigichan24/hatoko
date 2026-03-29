import Cocoa
import SwiftUI

@preconcurrency @MainActor
final class InlineSuggestionWindow {

    private var window: NSWindow?

    nonisolated func show(suggestion: String, at origin: NSPoint) {
        MainActor.assumeIsolated {
            showImpl(view: InlineSuggestionView(suggestion: suggestion), at: origin)
        }
    }

    nonisolated func showLoading(at origin: NSPoint) {
        MainActor.assumeIsolated {
            showImpl(view: InlineSuggestionView(suggestion: nil), at: origin)
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

    private func showImpl(view: InlineSuggestionView, at origin: NSPoint) {
        hide()

        let hostingView = NSHostingView(rootView: view)
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

        window = panel
    }
}
