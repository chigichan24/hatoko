import Cocoa
import InputMethodKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, Sendable {

    private var server: IMKServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String else {
            return
        }
        server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)
    }
}
