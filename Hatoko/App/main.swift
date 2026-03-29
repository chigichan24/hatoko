import Cocoa

// NSApplicationMain reads NSPrincipalClass from Info.plist to instantiate
// HatokoApplication as the shared NSApplication. This ensures the delegate
// is set and applicationDidFinishLaunching is called.
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
