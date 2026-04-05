import Cocoa
import SwiftUI

/// IME apps run as background agents without a main menu, so standard
/// edit key equivalents (Cmd+V/C/X/A) are never dispatched by the menu.
/// This subclass forwards them manually to the responder chain.
private class EditableWindow: NSWindow {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if super.performKeyEquivalent(with: event) {
            return true
        }
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers == [.command] else { return false }

        let action: Selector? = switch event.charactersIgnoringModifiers {
        case "v": #selector(NSText.paste(_:))
        case "c": #selector(NSText.copy(_:))
        case "x": #selector(NSText.cut(_:))
        case "a": #selector(NSText.selectAll(_:))
        default: nil
        }
        guard let action else { return false }
        return NSApp.sendAction(action, to: nil, from: self)
    }
}

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

        let newWindow = EditableWindow(contentViewController: hostingController)
        newWindow.title = L10n.Settings.windowTitle
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.titlebarSeparatorStyle = .none
        newWindow.toolbarStyle = .unified
        newWindow.level = .floating
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)

        window = newWindow

        NSApp.activate()
    }
}
