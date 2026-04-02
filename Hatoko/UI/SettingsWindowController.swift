import Cocoa
import SwiftUI

@MainActor
final class SettingsWindowController {

    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func showSettings() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Hatoko 設定"
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.titlebarSeparatorStyle = .none
        newWindow.toolbarStyle = .unified
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)

        window = newWindow

        NSApp.activate()
    }
}
