import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppEnvironment.engine.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppEnvironment.stateStore.flush()
        AppEnvironment.historyStore.flush()
    }
}
