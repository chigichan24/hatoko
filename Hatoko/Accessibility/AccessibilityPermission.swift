import ApplicationServices

enum AccessibilityPermission {

    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestTrust() {
        // Use the raw string to avoid concurrency-safety warnings with the global CFString constant
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
