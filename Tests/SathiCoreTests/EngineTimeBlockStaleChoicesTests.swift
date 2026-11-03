import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block stale calendar choices")
struct EngineTimeBlockStaleChoicesTests {
    private func deletedWorkThenEnded() -> EngineHarness {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 5)
        h.calendarWriter.choices.removeAll { $0.id == "work" }
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.engine.endBlock()
        return h
    }

    @Test func waitingRefreshesTheChoices() {
        let h = deletedWorkThenEnded()
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
        #expect(h.engine.calendarChoices().map(\.id) == ["home"])
        #expect(h.engine.calendarTitle("work") == nil)
    }

    @Test func theDefaultSkipsTheDeletedCalendar() {
        #expect(deletedWorkThenEnded().engine.waitingSaveCalendarID == "home")
    }

    @Test func aFailedSaveRefreshesTheChoicesAndKeepsThePopup() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 5)
        h.calendarWriter.nextSaveResult = .failed
        h.engine.endBlock()
        h.engine.pickWaitingCalendar("home")
        h.calendarWriter.choices.removeAll { $0.id == "home" }
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.engine.saveWaitingBlock(to: "home")
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
        #expect(h.engine.calendarChoices().map(\.id) == ["work"])
        #expect(h.engine.waitingSaveCalendarID == "work")
        #expect(h.presenter.calls.last == .showBlockCalendarGone)
    }
}
