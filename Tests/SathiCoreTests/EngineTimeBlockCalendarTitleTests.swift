import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block calendar title and pick")
struct EngineTimeBlockCalendarTitleTests {
    private func waiting() -> EngineHarness {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 5)
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.engine.endBlock()
        return h
    }

    @Test func startKeepsTheCalendarTitle() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        #expect(h.engine.timeBlock?.calendarTitle == "Gmail Work")
        #expect(h.store.live.timeBlock?.calendarTitle == "Gmail Work")
    }

    @Test func changingTheCalendarUpdatesTheTitle() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.engine.setBlockCalendar("home")
        #expect(h.engine.timeBlock?.calendarTitle == "Home")
    }

    @Test func aGoneCalendarKeepsItsTitleOnTheWaitingBlock() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.calendarWriter.choices.removeAll { $0.id == "work" }
        h.engine.refreshCalendarAccess()
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.advance(minutes: 30)
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
        #expect(h.engine.timeBlock?.calendarTitle == "Gmail Work")
    }

    @Test func theWaitingSaveDefaultsToTheBlockCalendar() {
        #expect(waiting().engine.waitingSaveCalendarID == "work")
    }

    @Test func theWaitingSaveFallsBackWhenTheCalendarIsGone() {
        let h = waiting()
        h.calendarWriter.choices.removeAll { $0.id == "work" }
        h.engine.refreshCalendarAccess()
        #expect(h.engine.waitingSaveCalendarID == "home")
    }

    @Test func aPickChangesTheWaitingSave() {
        let h = waiting()
        h.engine.pickWaitingCalendar("home")
        #expect(h.engine.waitingSaveCalendarID == "home")
        #expect(h.engine.timeBlock?.calendarID == "work")
    }

    @Test func anUnknownPickIsIgnored() {
        let h = waiting()
        h.engine.pickWaitingCalendar("nope")
        #expect(h.engine.waitingCalendarPick == nil)
    }

    @Test func aPickNeedsAWaitingBlock() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.engine.pickWaitingCalendar("home")
        #expect(h.engine.waitingCalendarPick == nil)
    }

    @Test func savingClearsThePick() {
        let h = waiting()
        h.engine.pickWaitingCalendar("home")
        h.calendarWriter.nextSaveResult = nil
        h.engine.saveWaitingBlock(to: "home")
        #expect(h.engine.timeBlock == nil)
        #expect(h.engine.waitingCalendarPick == nil)
    }
}
