import ApplicationServices

actor ScreenReader {

    private static let hatokoBundleID = "com.chigichan24.inputmethod.Hatoko"
    private static let axBundleIdentifier = "AXBundleIdentifier"

    func captureScreenContext() -> ScreenContext? {
        guard AccessibilityPermission.isTrusted else { return nil }

        let systemWide = AXUIElementCreateSystemWide()

        guard let focusedApp = copyElementAttribute(systemWide, kAXFocusedApplicationAttribute) else {
            return nil
        }

        // Skip if Hatoko itself is focused
        if let bundleID = copyStringAttribute(focusedApp, Self.axBundleIdentifier),
           bundleID == Self.hatokoBundleID {
            return nil
        }

        let appName = copyStringAttribute(focusedApp, kAXTitleAttribute)

        let windowTitle = readWindowTitle(app: focusedApp)

        var focusedText: String?
        var selectedText: String?

        if let focusedElement = copyElementAttribute(focusedApp, kAXFocusedUIElementAttribute) {
            focusedText = copyStringAttribute(focusedElement, kAXValueAttribute)
            selectedText = copyStringAttribute(focusedElement, kAXSelectedTextAttribute)
        }

        guard appName != nil || windowTitle != nil || focusedText != nil || selectedText != nil else {
            return nil
        }

        return ScreenContext(
            appName: appName,
            windowTitle: windowTitle,
            focusedText: focusedText,
            selectedText: selectedText
        )
    }

    // MARK: - AXUIElement Helpers

    private func readWindowTitle(app: AXUIElement) -> String? {
        guard let window = copyElementAttribute(app, kAXFocusedWindowAttribute) else {
            return nil
        }
        return copyStringAttribute(window, kAXTitleAttribute)
    }

    private func copyElementAttribute(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var ref: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &ref)
        guard result == .success, let ref else { return nil }
        guard CFGetTypeID(ref) == AXUIElementGetTypeID() else { return nil }
        // swiftlint:disable:next force_cast
        return (ref as! AXUIElement)
    }

    private func copyStringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        var ref: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &ref)
        guard result == .success, let ref else { return nil }
        return ref as? String
    }
}
