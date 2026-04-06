import ApplicationServices

actor ScreenReader {

    private static let hatokoBundleID = "com.chigichan24.inputmethod.Hatoko"
    private static let axBundleIdentifier = "AXBundleIdentifier"
    private static let maxTreeDepth = 30
    private static let maxElementTextLength = 2000
    private static let maxCollectedFragments = 500

    private struct AppWindowInfo {
        let app: AXUIElement
        let appName: String?
        let window: AXUIElement?
        let windowTitle: String?
    }

    private struct TextFragment {
        let text: String
        let y: CGFloat
        let x: CGFloat
    }

    // MARK: - Public Capture Methods

    func captureFullWindowContext() -> ScreenContext? {
        guard let info = readAppAndWindow() else { return nil }

        var selectedText: String?
        if let focusedElement = copyElementAttribute(info.app, kAXFocusedUIElementAttribute) {
            selectedText = copyStringAttribute(focusedElement, kAXSelectedTextAttribute)
        }

        var fragments: [TextFragment] = []
        if let window = info.window {
            collectVisibleTexts(from: window, depth: 0, results: &fragments)
        }

        // Sort top-to-bottom, left-to-right
        fragments.sort { ($0.y, $0.x) < ($1.y, $1.x) }

        // Deduplicate adjacent overlapping text
        let deduped = deduplicateAdjacentFragments(fragments)

        let visibleText = deduped.isEmpty ? nil : deduped.joined(separator: "\n")

        guard info.appName != nil || info.windowTitle != nil
                || visibleText != nil || selectedText != nil else {
            return nil
        }

        return ScreenContext(
            appName: info.appName,
            windowTitle: info.windowTitle,
            focusedText: nil,
            selectedText: selectedText,
            visibleText: visibleText
        )
    }

    // MARK: - Tree Traversal

    private func collectVisibleTexts(
        from element: AXUIElement,
        depth: Int,
        results: inout [TextFragment]
    ) {
        guard depth < Self.maxTreeDepth, results.count < Self.maxCollectedFragments else { return }

        let position = copyPositionAttribute(element)

        // Try kAXValueAttribute first (text fields), then kAXTitleAttribute (labels)
        if let text = extractText(from: element) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let truncated = String(trimmed.prefix(Self.maxElementTextLength))
                let y = position?.y ?? CGFloat.infinity
                let x = position?.x ?? 0
                results.append(TextFragment(text: truncated, y: y, x: x))
            }
        }

        // Recurse into children
        guard let children = copyArrayAttribute(element, kAXChildrenAttribute) else { return }
        for child in children {
            collectVisibleTexts(from: child, depth: depth + 1, results: &results)
        }
    }

    private func extractText(from element: AXUIElement) -> String? {
        if let value = copyStringAttribute(element, kAXValueAttribute), !value.isEmpty {
            return value
        }
        if let title = copyStringAttribute(element, kAXTitleAttribute), !title.isEmpty {
            return title
        }
        return nil
    }

    /// Removes adjacent fragments where one text contains the other.
    /// Only compares consecutive elements after position-based sorting.
    private func deduplicateAdjacentFragments(_ fragments: [TextFragment]) -> [String] {
        var result: [String] = []
        for fragment in fragments {
            if let last = result.last {
                // Skip if this text is contained in the previous, or vice versa
                if last.contains(fragment.text) { continue }
                if fragment.text.contains(last) {
                    result[result.count - 1] = fragment.text
                    continue
                }
            }
            result.append(fragment.text)
        }
        return result
    }

    // MARK: - Shared Helpers

    private func readAppAndWindow() -> AppWindowInfo? {
        guard AccessibilityPermission.isTrusted else { return nil }

        let systemWide = AXUIElementCreateSystemWide()

        guard let focusedApp = copyElementAttribute(systemWide, kAXFocusedApplicationAttribute) else {
            return nil
        }

        if let bundleID = copyStringAttribute(focusedApp, Self.axBundleIdentifier),
           bundleID == Self.hatokoBundleID {
            return nil
        }

        let appName = copyStringAttribute(focusedApp, kAXTitleAttribute)
        let window = copyElementAttribute(focusedApp, kAXFocusedWindowAttribute)
        let windowTitle: String? = if let window {
            copyStringAttribute(window, kAXTitleAttribute)
        } else {
            nil
        }

        return AppWindowInfo(app: focusedApp, appName: appName, window: window, windowTitle: windowTitle)
    }

    // MARK: - AXUIElement Helpers

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

    private func copyArrayAttribute(_ element: AXUIElement, _ attribute: String) -> [AXUIElement]? {
        var ref: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &ref)
        guard result == .success, let ref else { return nil }
        return ref as? [AXUIElement]
    }

    private func copyPositionAttribute(_ element: AXUIElement) -> CGPoint? {
        var ref: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &ref)
        guard result == .success, let ref else { return nil }
        guard CFGetTypeID(ref) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(ref as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }
}
