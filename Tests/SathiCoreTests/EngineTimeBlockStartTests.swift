import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block start")
struct EngineTimeBlockStartTests {
    private let t0 = day(2026, 3, 4, 10)

    @Test func startSavesAPlannedBlock() throws {
        let h = EngineHarness.quiet()
        let result = h.engine.startBlock(title: "Plan", length: .minutes(45), calendarID: "work")
        guard case let .started(id) = result else { Issue.record("not started"); return }
        let block = try #require(h.engine.timeBlock)
        #expect(block.id == id)
        #expect(block.title == "Plan")
        #expect(block.startedAt == t0)
        #expect(block.length == .minutes(45))
        #expect(block.plannedEnd == t0.addingTimeInterval(45 * Timing.minute))
        #expect(block.calendarID == "work")
        #expect(block.savedEventID == nil)
        #expect(block.nextCheckIn == nil)
        #expect(!block.waitingForCalendar)
        #expect(h.store.live.timeBlock == block)
    }

    @Test func startRemembersTheLength() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(45))
        #expect(h.store.prefs.timeBlock.lastLength == .minutes(45))
        h.engine.endBlock()
        h.startBlock("Plan", .open)
        #expect(h.store.prefs.timeBlock.lastLength == .open)
    }

    @Test func openBlockHasNoEndAndAFirstCheckIn() throws {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .open)
        let block = try #require(h.engine.timeBlock)
        #expect(block.plannedEnd == nil)
        #expect(block.nextCheckIn == t0.addingTimeInterval(Timing.blockCheckIn))
    }

    @Test func startCleansTheTitle() {
        let h = EngineHarness.quiet()
        h.startBlock("   \n ")
        #expect(h.engine.timeBlock?.title == "Work")
    }

    @Test func deniedAccessStartsNothing() async {
        let h = EngineHarness.quiet()
        h.calendarWriter.access = .denied
        await h.engine.requestCalendarAccess()
        let result = h.engine.startBlock(title: "Plan", length: .minutes(30), calendarID: "work")
        #expect(result == .noAccess)
        #expect(h.engine.timeBlock == nil)
        #expect(h.store.live.timeBlock == nil)
        #expect(h.presenter.blockNotes.isEmpty)
    }

    @Test func noCalendarStartsNothing() {
        let h = EngineHarness.quiet()
        h.calendarWriter.choices = []
        let result = h.engine.startBlock(title: "Plan", length: .minutes(30), calendarID: "work")
        #expect(result == .noCalendar)
        #expect(h.engine.timeBlock == nil)
    }

    @Test func startWhileRunningSavesTheOldBlock() throws {
        let h = EngineHarness.quiet()
        h.startBlock("Old")
        h.advance(minutes: 12)
        h.startBlock("New", .minutes(15), calendar: "home")
        #expect(h.calendarWriter.saved == [
            CalendarEventDraft(calendarID: "work", title: "Old", start: t0, end: t0.addingTimeInterval(12 * Timing.minute))
        ])
        #expect(h.presenter.blockNotes.contains(.savedPrevious(minutes: 12, title: "Old", calendarTitle: "Gmail Work")))
        let block = try #require(h.engine.timeBlock)
        #expect(block.title == "New")
        #expect(block.calendarID == "home")
    }

    @Test func undoRemovesTheBlockAndWritesNothing() {
        let h = EngineHarness.quiet()
        let id = h.startBlock()
        h.engine.undoBlockStart(id)
        #expect(h.engine.timeBlock == nil)
        #expect(h.store.live.timeBlock == nil)
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test func undoOfAnOldBlockKeepsTheRunningOne() {
        let h = EngineHarness.quiet()
        let old = h.startBlock("Old")
        h.advance(minutes: 5)
        h.startBlock("New")
        h.engine.undoBlockStart(old)
        #expect(h.engine.timeBlock?.title == "New")
    }

    @Test func noHistoryEventsForABlock() {
        let h = EngineHarness.quiet()
        h.startBlock()
        h.advance(minutes: 10)
        h.engine.endBlock()
        #expect(h.history.appended.isEmpty)
    }
}
