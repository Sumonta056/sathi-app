import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page event read")
struct EngineCalendarPageReadTests {
    func event(_ id: String, _ from: Date, calendar: String = "work") -> CalendarEventInfo {
        CalendarEventInfo(id: id, title: id, start: from, end: from.addingTimeInterval(3600), calendarID: calendar)
    }

    func today(_ h: EngineHarness, kind: ReportRange = .day) -> CalendarPageRange {
        .containing(h.clock.now, kind: kind, calendar: h.engine.calendar)
    }

    @Test func minuteTickDoesNotReadAgain() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        h.calendarWriter.eventsValue = [event("e1", day(2026, 3, 4, 9))]
        _ = h.engine.calendarPageBase(today(h))
        h.advance(minutes: 1)
        let data = h.engine.calendarPageBase(today(h))
        #expect(h.calendarWriter.eventReads.count == 1)
        #expect(data.blocks.map(\.title) == ["e1"])
    }

    @Test func storeChangeReadsAgain() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        _ = h.engine.calendarPageBase(today(h))
        h.engine.storesChanged()
        _ = h.engine.calendarPageBase(today(h))
        #expect(h.calendarWriter.eventReads.count == 2)
    }

    @Test func rangeChangeReadsAgain() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        _ = h.engine.calendarPageBase(today(h))
        _ = h.engine.calendarPageBase(today(h).next)
        _ = h.engine.calendarPageBase(today(h, kind: .week))
        #expect(h.calendarWriter.eventReads.count == 3)
    }

    @Test func hidingACalendarReadsAgain() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        _ = h.engine.calendarPageBase(today(h))
        h.engine.setCalendarShown("home", false)
        _ = h.engine.calendarPageBase(today(h))
        #expect(h.calendarWriter.eventReads.count == 2)
    }

    @Test func runningActivityGrowsFromCachedEvents() {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        h.engine.data.live.tracker.running = RunningActivity(
            text: "Focus", start: day(2026, 3, 4, 10), expectedLength: .minutes(60), askAt: day(2026, 3, 4, 11)
        )
        _ = h.engine.calendarPageBase(today(h))
        h.clock.advance(minutes: 20)
        let data = h.engine.calendarPageBase(today(h))
        #expect(data.stats.tracked == 20 * 60)
        #expect(h.calendarWriter.eventReads.count == 1)
    }
}
