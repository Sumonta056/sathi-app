import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Main window lifecycle")
struct MainWindowLifecycleTests {
    private final class Spy {
        var shown: [NSWindow] = []
        var closed = 0
    }

    private func controller(_ h: EngineHarness, _ spy: Spy) -> UIController {
        let c = UIController()
        c.engine = h.engine
        c.mainWindowShown = { spy.shown.append($0) }
        c.mainWindowClosed = { spy.closed += 1 }
        return c
    }

    @Test func secondOpenReusesTheWindowAndChangesThePage() throws {
        let h = EngineHarness()
        let spy = Spy()
        let c = controller(h, spy)
        c.showMain(.dashboard(.day))
        let first = try #require(c.mainWindow)
        c.showMain(.settings(.tracker))
        #expect(c.mainWindow === first)
        #expect(c.mainRoute?.page == .settings(.tracker))
        #expect(spy.shown.count == 2)
        #expect(spy.shown.allSatisfy { $0 === first })
    }

    @Test func closeFreesTheWindowAndRoute() throws {
        let h = EngineHarness()
        let spy = Spy()
        let c = controller(h, spy)
        c.showMain(.dashboard(.week))
        let window = try #require(c.mainWindow)
        c.mainWillClose()
        #expect(c.mainWindow == nil)
        #expect(c.mainRoute == nil)
        #expect(window.contentView == nil)
        #expect(spy.closed == 1)
    }

    @Test func openAfterCloseMakesANewWindowOnTheAskedPage() throws {
        let h = EngineHarness()
        let spy = Spy()
        let c = controller(h, spy)
        c.showMain(.dashboard(.week))
        let old = try #require(c.mainWindow)
        c.mainWillClose()
        c.showMain(.dashboard(.day))
        #expect(c.mainWindow !== old)
        #expect(c.mainRoute?.page == .dashboard(.day))
    }

    @Test func reopenBringsTheOpenWindowBackOnItsPage() throws {
        let h = EngineHarness()
        let spy = Spy()
        let c = controller(h, spy)
        c.showMain(.dashboard(.week))
        let window = try #require(c.mainWindow)
        c.reopenMain()
        #expect(c.mainWindow === window)
        #expect(c.mainRoute?.page == .dashboard(.week))
        #expect(spy.shown.count == 2)
    }

    @Test func reopenWithNoWindowOpensToday() {
        let h = EngineHarness()
        let spy = Spy()
        let c = controller(h, spy)
        c.reopenMain()
        #expect(c.mainRoute?.page == .dashboard(.day))
        #expect(spy.shown.count == 1)
    }

    @Test func everyOpenStartsAFreshPage() {
        let h = EngineHarness()
        let c = controller(h, Spy())
        c.showMain(.dashboard(.week))
        let first = c.mainRoute?.opens
        c.showMain(.dashboard(.week))
        #expect(c.mainRoute?.opens != first)
    }
}
