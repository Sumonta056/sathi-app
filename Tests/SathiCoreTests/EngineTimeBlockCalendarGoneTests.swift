import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block calendar gone")
struct EngineTimeBlockCalendarGoneTests {
    private let t0 = day(2026, 3, 4, 10)
    private var end30: Date { t0.addingTimeInterval(30 * Timing.minute) }

    @Test(arguments: [CalendarSaveResult.calendarMissing, .failed])
    func autoEndKeepsTheBlockWaiting(_ result: CalendarSaveResult) throws {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.calendarWriter.nextSaveResult = result
        h.advance(minutes: 30)
        let block = try #require(h.engine.timeBlock)
        #expect(block.waitingForCalendar)
        #expect(block.endedAt == end30)
        #expect(h.store.live.timeBlock == block)
        #expect(h.presenter.calls.contains(.showBlockCalendarGone))
        #expect(!h.presenter.calls.contains(.showBlockDone))
        #expect(h.engine.finishedBlock == nil)
    }

    @Test func manualEndKeepsTheBlockWaiting() throws {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(60))
        h.advance(minutes: 20)
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.engine.endBlock()
        let block = try #require(h.engine.timeBlock)
        #expect(block.waitingForCalendar)
        #expect(block.endedAt == t0.addingTimeInterval(20 * Timing.minute))
        #expect(h.presenter.calls.contains(.showBlockCalendarGone))
    }

    @Test func aWaitingBlockStaysUntilTheUserPicks() throws {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.advance(minutes: 5)
        h.engine.endBlock()
        let ended = try #require(h.engine.timeBlock?.endedAt)
        h.advance(minutes: 13 * 60)
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
        #expect(h.engine.timeBlock?.endedAt == ended)
        #expect(!h.presenter.calls.contains(.showBlockCheckIn))
    }

    @Test func savingToAnotherCalendarWritesTheOriginalRange() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.advance(minutes: 30)
        h.advance(minutes: 10)
        h.calendarWriter.nextSaveResult = nil
        h.engine.saveWaitingBlock(to: "home")
        #expect(h.calendarWriter.saved.last == CalendarEventDraft(calendarID: "home", title: "Plan", start: t0, end: end30))
        #expect(h.engine.timeBlock == nil)
        #expect(h.store.live.timeBlock == nil)
        #expect(h.presenter.calls.contains(.closeBlockCalendarGone))
    }

    @Test func aFailedRetryKeepsWaiting() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.advance(minutes: 30)
        h.engine.saveWaitingBlock(to: "home")
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
        #expect(h.engine.timeBlock?.endedAt == end30)
    }
}

@MainActor
@Suite("Engine time block start calendar")
struct EngineTimeBlockStartCalendarTests {
    @Test func prefsDefaultWins() {
        let h = EngineHarness.quiet { $0.prefs.timeBlock.defaultCalendarID = "home" }
        h.calendarWriter.defaultID = "work"
        #expect(h.engine.startCalendarID == "home")
    }

    @Test func aMissingPrefsDefaultFallsToTheWriterDefault() {
        let h = EngineHarness.quiet { $0.prefs.timeBlock.defaultCalendarID = "gone" }
        h.calendarWriter.defaultID = "home"
        #expect(h.engine.startCalendarID == "home")
    }

    @Test func noDefaultFallsToTheFirstChoice() {
        let h = EngineHarness.quiet()
        h.calendarWriter.defaultID = nil
        #expect(h.engine.startCalendarID == "work")
    }

    @Test func noChoicesGivesNil() {
        let h = EngineHarness.quiet()
        h.calendarWriter.choices = []
        #expect(h.engine.startCalendarID == nil)
    }
}
