import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block end")
struct EngineTimeBlockEndTests {
    private let t0 = day(2026, 3, 4, 10)

    @Test func endWritesOneEvent() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(60), calendar: "home")
        h.advance(minutes: 20)
        h.engine.endBlock()
        #expect(h.calendarWriter.saved == [
            CalendarEventDraft(calendarID: "home", title: "Plan", start: t0, end: t0.addingTimeInterval(20 * Timing.minute))
        ])
        #expect(h.engine.timeBlock == nil)
        #expect(h.store.live.timeBlock == nil)
        #expect(h.engine.finishedBlock == nil)
    }

    @Test func endOfAnOpenBlockWritesTheEndNow() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        h.advance(minutes: 42)
        h.engine.endBlock()
        #expect(h.calendarWriter.saved.map(\.end) == [t0.addingTimeInterval(42 * Timing.minute)])
    }

    @Test func shorterThanAMinuteWritesNothing() {
        let h = EngineHarness.quiet()
        h.startBlock()
        h.clock.advance(minutes: 0.5)
        h.engine.endBlock()
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.presenter.blockNotes.contains(.tooShort))
        #expect(h.engine.timeBlock == nil)
    }

    @Test func exactlyAMinuteIsSaved() {
        let h = EngineHarness.quiet()
        h.startBlock()
        h.clock.advance(minutes: Timing.blockMinimum / Timing.minute)
        h.engine.endBlock()
        #expect(h.calendarWriter.saved.count == 1)
        #expect(!h.presenter.blockNotes.contains(.tooShort))
    }

    @Test func renameChangesTheSavedTitle() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan")
        h.advance(minutes: 5)
        h.engine.renameBlock("Deep work")
        #expect(h.engine.timeBlock?.title == "Deep work")
        h.engine.endBlock()
        #expect(h.calendarWriter.saved.map(\.title) == ["Deep work"])
    }

    @Test func renameCleansTheText() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan")
        h.engine.renameBlock("  \n ")
        #expect(h.engine.timeBlock?.title == "Work")
    }

    @Test func calendarChangeMovesTheSavedEvent() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", calendar: "work")
        h.advance(minutes: 5)
        h.engine.setBlockCalendar("home")
        #expect(h.engine.timeBlock?.calendarID == "home")
        h.engine.endBlock()
        #expect(h.calendarWriter.saved.map(\.calendarID) == ["home"])
    }

    @Test func pauseDoesNotAffectABlock() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.engine.pause(hours: 2)
        h.advance(minutes: 30)
        #expect(h.calendarWriter.saved.count == 1)
    }
}
