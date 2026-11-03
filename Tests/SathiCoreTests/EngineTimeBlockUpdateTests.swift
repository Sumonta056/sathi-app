import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block event update")
struct EngineTimeBlockUpdateTests {
    private let t0 = day(2026, 3, 4, 10)
    private var end30: Date { t0.addingTimeInterval(30 * Timing.minute) }
    private var end45: Date { end30.addingTimeInterval(Timing.blockExtend) }

    private func extended() -> EngineHarness {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 30)
        h.engine.extendBlock()
        return h
    }

    @Test func renameAfterExtendReachesTheEvent() {
        let h = extended()
        h.engine.renameBlock("Deep work")
        h.advance(minutes: 15)
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.updated.map(\.0) == ["e1"])
        #expect(h.calendarWriter.updated.last?.1 == CalendarEventDraft(calendarID: "work", title: "Deep work", start: t0, end: end45))
    }

    @Test func calendarChangeAfterExtendReachesTheEvent() {
        let h = extended()
        h.engine.setBlockCalendar("home")
        h.advance(minutes: 15)
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.updated.last?.1 == CalendarEventDraft(calendarID: "home", title: "Plan", start: t0, end: end45))
    }

    @Test func aFailedUpdateWaitsAndSavesNoSecondEvent() throws {
        let h = extended()
        h.calendarWriter.nextUpdateResult = .failed
        h.advance(minutes: 15)
        #expect(h.calendarWriter.saved.count == 1)
        let block = try #require(h.engine.timeBlock)
        #expect(block.waitingForCalendar)
        #expect(block.endedAt == end45)
        #expect(h.presenter.calls.contains(.showBlockCalendarGone))
        #expect(h.engine.finishedBlock == nil)
    }

    @Test func saveWaitingBlockUpdatesTheSavedEvent() {
        let h = extended()
        h.calendarWriter.nextUpdateResult = .failed
        h.advance(minutes: 15)
        h.calendarWriter.nextUpdateResult = nil
        h.engine.saveWaitingBlock(to: "home")
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.updated.last?.0 == "e1")
        #expect(h.calendarWriter.updated.last?.1 == CalendarEventDraft(calendarID: "home", title: "Plan", start: t0, end: end45))
        #expect(h.engine.timeBlock == nil)
        #expect(h.presenter.calls.contains(.closeBlockCalendarGone))
    }

    @Test func aLateExtendCountsFromTheTap() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 30)
        h.advance(minutes: 20)
        h.engine.extendBlock()
        #expect(h.engine.timeBlock?.plannedEnd == end30.addingTimeInterval(20 * Timing.minute + Timing.blockExtend))
    }

    @Test func anEmptyEventIDIsTreatedAsNoSavedID() throws {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.calendarWriter.nextSaveResult = .saved(eventID: "")
        h.advance(minutes: 30)
        let done = try #require(h.engine.finishedBlock)
        #expect(done.block.savedEventID == nil)
        #expect(h.engine.timeBlock == nil)
        h.calendarWriter.nextSaveResult = nil
        h.engine.extendBlock()
        h.advance(minutes: 15)
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.calendarWriter.saved.count == 2)
    }
}
