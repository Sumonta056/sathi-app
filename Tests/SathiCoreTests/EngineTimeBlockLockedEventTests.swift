import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine time block locked event")
struct EngineTimeBlockLockedEventTests {
    private let t0 = day(2026, 3, 4, 10)

    @Test func aLockedEventIsTreatedAsMissing() {
        #expect(CalendarSaveResult.lockedEvent == .calendarMissing)
    }

    @Test func anEventLockedInCalendarGetsANewEventAndTheBlockDoesNotWait() {
        let h = EngineHarness.quiet()
        h.startBlock("Plan", .minutes(30))
        h.advance(minutes: 30)
        h.engine.extendBlock()
        h.calendarWriter.lockedEventIDs = ["e1"]
        h.advance(minutes: 15)
        #expect(h.calendarWriter.updated.map(\.0) == ["e1"])
        #expect(h.calendarWriter.saved.count == 2)
        #expect(h.calendarWriter.saved.last == CalendarEventDraft(
            calendarID: "work", title: "Plan", start: t0, end: t0.addingTimeInterval(30 * Timing.minute + Timing.blockExtend)
        ))
        #expect(h.engine.timeBlock?.waitingForCalendar != true)
        #expect(!h.presenter.calls.contains(.showBlockCalendarGone))
    }
}
