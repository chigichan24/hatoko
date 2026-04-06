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
    private let state = DangerousReadIndicatorState()

    nonisolated func show(remainingSeconds: Int) {
        MainActor.assumeIsolated {
            state.remainingSeconds = remainingSeconds
            if panel != nil { return }
            createPanel()
        }
    }

    nonisolated func hide() {
        MainActor.assumeIsolated {
            state.isScanning = false
            panel?.orderOut(nil)
            panel = nil
            hostingController = nil
        }
    }

    nonisolated func updateRemainingTime(_ seconds: Int) {
        MainActor.assumeIsolated {
            state.remainingSeconds = seconds
        }
    }

    nonisolated func setScanning(_ scanning: Bool) {
        MainActor.assumeIsolated {
            state.isScanning = scanning
        }
    }

    nonisolated var isVisible: Bool {
        MainActor.assumeIsolated {
            panel?.isVisible ?? false
        }
    }

    private func createPanel() {
        let view = DangerousReadIndicatorView(state: state)
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

// MARK: - Observable State

@Observable
final class DangerousReadIndicatorState: @unchecked Sendable {
    var remainingSeconds: Int = 0
    var isScanning: Bool = false
    var scanFrame: Int = 0
}

// MARK: - Indicator View

struct DangerousReadIndicatorView: View {

    var state: DangerousReadIndicatorState

    private static let pacmanFrames = ["ᗧ···", "ᗧ ··", "ᗧ  ·", "ᗧ   "]

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(L10n.DangerousRead.Indicator.active)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            if state.isScanning {
                Text(Self.pacmanFrames[state.scanFrame])
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
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
        .task(id: state.isScanning) {
            guard state.isScanning else { return }
            state.scanFrame = 0
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(200))
                } catch {
                    return
                }
                state.scanFrame = (state.scanFrame + 1) % Self.pacmanFrames.count
            }
        }
    }

    private var formattedTime: String {
        let minutes = state.remainingSeconds / 60
        let seconds = state.remainingSeconds % 60
        return String(format: "(%d:%02d)", minutes, seconds)
    }
}
