import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Settings window")
struct SettingsWindowTests {
    @Test func windowIsKeptAfterCloseAndUsesTheWatcher() {
        let watcher = WindowCloseWatcher()
        let w = SettingsWindow.make(engine: EngineHarness().engine, closeWatcher: watcher)
        #expect(w.isReleasedWhenClosed == false)
        #expect(w.delegate === watcher)
    }

    @Test func titleTextNeverDrawsOverScrolledContent() {
        let w = SettingsWindow.make(engine: EngineHarness().engine, closeWatcher: WindowCloseWatcher())
        #expect(w.titleVisibility == .hidden)
        #expect(w.title == "Sathi Settings")
    }

    @Test func windowWillCloseRunsOnClose() {
        let watcher = WindowCloseWatcher()
        var closed = 0
        watcher.onClose = { closed += 1 }
        watcher.windowWillClose(Notification(name: NSWindow.willCloseNotification))
        #expect(closed == 1)
    }
}
