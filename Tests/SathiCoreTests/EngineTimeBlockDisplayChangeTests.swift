import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block display change")
struct EngineTimeBlockDisplayChangeTests {
    private func count(_ h: EngineHarness, _ call: SpyPresenter.Call) -> Int {
        h.presenter.calls.filter { $0 == call }.count
    }

    @Test func switchingToWidgetShowsThePillForARunningBlock() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.engine.data.prefs.timeBlock.display = .widget
        #expect(count(h, .showBlockWidget) == 1)
    }

    @Test func switchingToMenuBarClosesThePill() {
        let h = EngineHarness.quiet { $0.prefs.timeBlock.display = .widget }
        h.startBlock("Plan", .minutes(30))
        h.engine.data.prefs.timeBlock.display = .menuBar
        #expect(h.presenter.calls.last == .closeBlockWidget)
    }

    @Test func switchingToWidgetShowsNoStartedNote() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.engine.data.prefs.timeBlock.display = .widget
        #expect(h.presenter.blockNotes.isEmpty)
    }

    @Test func switchingWithNoBlockShowsNothing() {
        let h = EngineHarness.quiet()
        h.engine.data.prefs.timeBlock.display = .widget
        h.engine.data.prefs.timeBlock.display = .menuBar
        #expect(count(h, .showBlockWidget) == 0)
        #expect(count(h, .closeBlockWidget) == 0)
    }

    @Test func switchingWhileTheBlockWaitsForACalendarShowsNoPill() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 5)
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.engine.endBlock()
        h.engine.data.prefs.timeBlock.display = .widget
        #expect(count(h, .showBlockWidget) == 0)
    }

    @Test func changingAnotherTimeBlockPrefKeepsThePill() {
        let h = EngineHarness.quiet { $0.prefs.timeBlock.display = .widget }
        h.startBlock("Plan", .minutes(30))
        let shown = count(h, .showBlockWidget)
        h.engine.data.prefs.timeBlock.playsSound = false
        #expect(count(h, .showBlockWidget) == shown)
        #expect(count(h, .closeBlockWidget) == 0)
    }

    @Test func theNextBlockFollowsTheNewMode() {
        let h = EngineHarness.quiet { $0.prefs.timeBlock.display = .widget }
        h.engine.data.prefs.timeBlock.display = .menuBar
        h.startBlock("Plan", .minutes(30))
        #expect(count(h, .showBlockWidget) == 0)
    }
}
