import Cocoa
import SwiftUI

/// Floating red badge indicating Dangerous Read Mode is active.
///
/// Follows the same `@preconcurrency @MainActor` pattern as `InlineSuggestionWindow`.
/// Public methods are `nonisolated` with `MainActor.assumeIsolated` because they are
/// called from IMKInputController (always main thread).
@preconcurrency @MainActor
final class DangerousReadIndicatorWindow {

    private var panel: NSPanel?
    private var hostingController: NSHostingController<DangerousReadIndicatorView>?

    nonisolated func show(remainingSeconds: Int) {
        MainActor.assumeIsolated {
            if panel != nil {
                updateRemainingTime(remainingSeconds)
                return
            }
            createPanel(remainingSeconds: remainingSeconds)
        }
    }

    nonisolated func hide() {
        MainActor.assumeIsolated {
            panel?.orderOut(nil)
            panel = nil
            hostingController = nil
        }
    }

    nonisolated func updateRemainingTime(_ seconds: Int) {
        MainActor.assumeIsolated {
            let view = DangerousReadIndicatorView(remainingSeconds: seconds)
            hostingController?.rootView = view
        }
    }

    nonisolated var isVisible: Bool {
        MainActor.assumeIsolated {
            panel?.isVisible ?? false
        }
    }

    private func createPanel(remainingSeconds: Int) {
        let view = DangerousReadIndicatorView(remainingSeconds: remainingSeconds)
        let controller = NSHostingController(rootView: view)
        controller.view.layoutSubtreeIfNeeded()
        let size = controller.view.fittingSize

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - 8
        )

        let newPanel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.level = .statusBar
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.contentViewController = controller
        newPanel.orderFront(nil)

        panel = newPanel
        hostingController = controller
    }
}

struct DangerousReadIndicatorView: View {

    let remainingSeconds: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(L10n.DangerousRead.Indicator.active)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            Text(formattedTime)
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))
        }
        .font(.system(size: 12))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.red)
        )
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "(%d:%02d)", minutes, seconds)
    }
}
