import Cocoa

/// Manages the lifecycle of the Dangerous Read Mode session.
///
/// Marked `@preconcurrency @MainActor` because all state mutations and UI operations
/// require the main thread. `nonisolated` accessors use `MainActor.assumeIsolated`
/// because they are called from IMKInputController (always main thread) but cannot
/// be statically proven to be MainActor-isolated.
@preconcurrency @MainActor
final class DangerousReadModeController {

    private var activeState = false
    private(set) var latestScreenContext: ScreenContext?
    private var sessionStartTime: Date?
    private var captureTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private let indicatorWindow = DangerousReadIndicatorWindow()

    static let enabledKey = "dangerous_read_enabled"
    static let maxDurationKey = "dangerous_read_max_duration"
    static let captureIntervalKey = "dangerous_read_capture_interval"
    static let defaultMaxDuration = 300
    static let defaultCaptureInterval = 3

    nonisolated var isActive: Bool {
        MainActor.assumeIsolated { activeState }
    }

    nonisolated var currentScreenContext: ScreenContext? {
        MainActor.assumeIsolated { latestScreenContext }
    }

    var isEnabledInSettings: Bool {
        UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    var maxSessionDuration: Int {
        let stored = UserDefaults.standard.integer(forKey: Self.maxDurationKey)
        return stored > 0 ? stored : Self.defaultMaxDuration
    }

    var captureInterval: Int {
        let stored = UserDefaults.standard.integer(forKey: Self.captureIntervalKey)
        return stored > 0 ? stored : Self.defaultCaptureInterval
    }

    nonisolated func toggleSession() {
        MainActor.assumeIsolated {
            if activeState {
                stopSession()
            } else {
                startSession()
            }
        }
    }

    func startSession() {
        guard isEnabledInSettings else {
            NSSound.beep()
            return
        }

        guard AccessibilityPermission.isTrusted else {
            AccessibilityPermission.requestTrust()
            return
        }

        guard showConsentAlert() else { return }

        activeState = true
        sessionStartTime = Date()
        latestScreenContext = nil

        let duration = maxSessionDuration
        indicatorWindow.show(remainingSeconds: duration)
        startCaptureLoop()
        startCountdown(totalSeconds: duration)
    }

    func stopSession() {
        captureTask?.cancel()
        captureTask = nil
        countdownTask?.cancel()
        countdownTask = nil
        activeState = false
        sessionStartTime = nil
        latestScreenContext = nil
        indicatorWindow.hide()
    }

    var remainingSeconds: Int {
        guard let start = sessionStartTime else { return 0 }
        let elapsed = Int(Date().timeIntervalSince(start))
        return max(0, maxSessionDuration - elapsed)
    }

    // MARK: - Private

    private func startCaptureLoop() {
        let interval = captureInterval
        captureTask = Task {
            let reader = ScreenReader()
            while !Task.isCancelled {
                let context = await reader.captureScreenContext()
                guard !Task.isCancelled else { return }
                self.latestScreenContext = context
                do {
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    return
                }
            }
        }
    }

    private func startCountdown(totalSeconds: Int) {
        countdownTask = Task {
            var remaining = totalSeconds
            while remaining > 0, !Task.isCancelled {
                indicatorWindow.updateRemainingTime(remaining)
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                remaining -= 1
            }
            guard !Task.isCancelled else { return }
            NSSound.beep()
            stopSession()
        }
    }

    private func showConsentAlert() -> Bool {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = L10n.DangerousRead.Consent.title
        alert.informativeText = L10n.DangerousRead.Consent.message
        alert.alertStyle = .critical
        alert.addButton(withTitle: L10n.DangerousRead.Consent.start)
        alert.addButton(withTitle: L10n.DangerousRead.Consent.cancel)
        return alert.runModal() == .alertFirstButtonReturn
    }
}
