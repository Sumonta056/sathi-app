import AppKit
import SathiUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppMenu.install(in: NSApp.mainMenu)
        AppEnvironment.engine.start()
        let event = NSAppleEventManager.shared().currentAppleEvent
        let propData = event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue
        if !LaunchKind.isLoginItem(propData: propData) {
            AppEnvironment.engine.openMain(.today)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        AppEnvironment.engine.openMain(.today)
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppEnvironment.stateStore.flush()
        AppEnvironment.historyStore.flush()
        AppEnvironment.activityStore.flush()
    }
}
