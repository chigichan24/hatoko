import Cocoa
import InputMethodKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var server: IMKServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String else {
            fatalError("InputMethodConnectionName is not configured in Info.plist")
        }
        server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)
    }
}
