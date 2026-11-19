import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Main window")
struct MainWindowTests {
    private func make() -> NSWindow {
        make(WindowCloseWatcher())
    }

    private func make(_ watcher: WindowCloseWatcher) -> NSWindow {
        MainWindow.make(engine: EngineHarness().engine, route: MainRoute(.dashboard(.day)), closeWatcher: watcher)
    }

    @Test func windowIsATitledResizableWindow() {
        let mask = make().styleMask
        for style: NSWindow.StyleMask in [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView] {
            #expect(mask.contains(style))
        }
    }

    @Test func windowOpensAtTheMockupSizeWithAMinimum() {
        let w = make()
        #expect(w.contentRect(forFrameRect: w.frame).size == UIMetrics.mainWindowSize)
        #expect(w.contentMinSize == UIMetrics.mainWindowMinSize)
        #expect(UIMetrics.mainWindowSize == CGSize(width: 1200, height: 760))
    }

    @Test func windowIsDarkAndKeptAfterClose() {
        let watcher = WindowCloseWatcher()
        let w = make(watcher)
        #expect(w.isReleasedWhenClosed == false)
        #expect(w.delegate === watcher)
        #expect(w.appearance?.name == .darkAqua)
        #expect(w.contentView != nil)
    }

    @Test func windowWillCloseRunsOnClose() {
        let watcher = WindowCloseWatcher()
        var closed = 0
        watcher.onClose = { closed += 1 }
        watcher.windowWillClose(Notification(name: NSWindow.willCloseNotification))
        #expect(closed == 1)
    }
}
