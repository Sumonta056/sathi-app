import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block loop")
struct EngineTimeBlockLoopTests {
    private let t0 = day(2026, 3, 4, 10)
    private var end30: Date { t0.addingTimeInterval(30 * Timing.minute) }

    @Test func plannedBlockEndsAtItsEnd() throws {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 29)
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.engine.finishedBlock == nil)
        h.advance(minutes: 1)
        #expect(h.calendarWriter.saved == [CalendarEventDraft(calendarID: "work", title: "Plan", start: t0, end: end30)])
        #expect(h.engine.timeBlock == nil)
        #expect(h.store.live.timeBlock == nil)
        let done = try #require(h.engine.finishedBlock)
        #expect(done.end == end30)
        #expect(done.block.title == "Plan")
        #expect(done.block.savedEventID == "e1")
        #expect(done.calendarTitle == "Gmail Work")
        #expect(h.presenter.calls.contains(.showBlockDone))
    }

    @Test func donePopupPlaysPingWhenSoundIsOn() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(15))
        h.advance(minutes: 15)
        #expect(h.sound.played.contains(.ping))
    }

    @Test func donePopupIsSilentWhenSoundIsOff() {
        let h = EngineHarness.quiet { $0.prefs.timeBlock.playsSound = false }
        h.startBlock("Plan", .minutes(15))
        h.advance(minutes: 15)
        #expect(!h.sound.played.contains(.ping))
        #expect(h.presenter.calls.contains(.showBlockDone))
    }

    @Test func doneClosesThePopup() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(15))
        h.advance(minutes: 15)
        h.engine.dismissBlockDone()
        #expect(h.engine.finishedBlock == nil)
        #expect(h.presenter.calls.contains(.closeBlockDone))
    }

    @Test func aNewBlockClosesThePopup() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(15))
        h.advance(minutes: 15)
        h.startBlock("Next")
        #expect(h.engine.finishedBlock == nil)
        #expect(h.presenter.calls.contains(.closeBlockDone))
    }

    @Test func extendKeepsTheBlockRunning() throws {
        let h = EngineHarness.quiet()
        let id = h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 30)
        h.advance(minutes: 5)
        h.engine.extendBlock()
        let block = try #require(h.engine.timeBlock)
        #expect(block.id == id)
        #expect(block.startedAt == t0)
        #expect(block.savedEventID == "e1")
        #expect(block.plannedEnd == end30.addingTimeInterval(5 * Timing.minute + Timing.blockExtend))
        #expect(h.engine.finishedBlock == nil)
        #expect(h.presenter.calls.contains(.closeBlockDone))
    }

    @Test func theExtendedEndMovesTheSavedEvent() throws {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 30)
        h.engine.extendBlock()
        h.advance(minutes: 15)
        let newEnd = end30.addingTimeInterval(Timing.blockExtend)
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.updated.count == 1)
        #expect(h.calendarWriter.updated.first?.0 == "e1")
        #expect(h.calendarWriter.updated.first?.1 == CalendarEventDraft(calendarID: "work", title: "Plan", start: t0, end: newEnd))
        #expect(h.engine.timeBlock == nil)
        #expect(try #require(h.engine.finishedBlock).end == newEnd)
    }

    @Test func endingAnExtendedBlockEarlyMovesTheEvent() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 30)
        h.engine.extendBlock()
        h.advance(minutes: 5)
        h.engine.endBlock()
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.updated.map(\.1.end) == [end30.addingTimeInterval(5 * Timing.minute)])
    }

    @Test func aMissingEventOnExtendSavesTheWholeRange() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 30)
        h.engine.extendBlock()
        h.calendarWriter.nextUpdateResult = .calendarMissing
        h.advance(minutes: 15)
        #expect(h.calendarWriter.saved.count == 2)
        #expect(h.calendarWriter.saved.last == CalendarEventDraft(
            calendarID: "work", title: "Plan", start: t0, end: end30.addingTimeInterval(Timing.blockExtend)
        ))
    }

    @Test func capEndsAnOpenBlockAtTwelveHours() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        h.advance(minutes: 13 * 60)
        #expect(h.calendarWriter.saved == [
            CalendarEventDraft(calendarID: "work", title: "Plan", start: t0, end: t0.addingTimeInterval(Timing.blockCap))
        ])
        #expect(h.engine.timeBlock == nil)
    }

    @Test func nextTickWaitsForTheNextMinuteChange() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(120))
        h.clock.advance(minutes: 0.5)
        h.engine.tick()
        let delay = h.engine.nextTickDelay()
        #expect(delay > 29 && delay < 31)
    }
}
