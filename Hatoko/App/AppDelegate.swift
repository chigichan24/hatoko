import Cocoa
import InputMethodKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var server: IMKServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        LLMBackend.migrateIfNeeded()
        guard let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String else {
            fatalError("InputMethodConnectionName is not configured in Info.plist")
        }
        NSLog("[Hatoko] Starting IMKServer with connection: %@ bundle: %@", connectionName, Bundle.main.bundleIdentifier ?? "nil")
        server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)
        NSLog("[Hatoko] IMKServer created: %@", server?.description ?? "nil")
    }
}
