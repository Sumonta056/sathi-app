import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page data")
struct EngineCalendarPageDataTests {
    func event(_ id: String, _ from: Date, minutes: Int = 60, calendar: String = "work") -> CalendarEventInfo {
        CalendarEventInfo(id: id, title: id, start: from, end: from.addingTimeInterval(TimeInterval(minutes * 60)), calendarID: calendar)
    }

    func wednesday(_ h: EngineHarness, kind: ReportRange = .day) -> CalendarPageRange {
        .containing(day(2026, 3, 4, 12), kind: kind, calendar: h.engine.calendar)
    }

    func hasActivityBlock(_ data: CalendarPageData) -> Bool {
        data.blocks.contains { if case .activity = $0.source { true } else { false } }
    }

    @Test func trackerOffShowsEventsOnly() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        h.calendarWriter.eventsValue = [event("e1", day(2026, 3, 4, 9))]
        let data = h.engine.calendarPage(wednesday(h))
        #expect(data.blocks.map(\.title) == ["e1"])
        #expect(!hasActivityBlock(data))
        #expect(data.stats.planned == 60 * 60)
    }

    @Test func readCoversTheRangeIntervalOnce() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        let reads = h.calendarWriter.eventReads.count
        let range = wednesday(h, kind: .week)
        _ = h.engine.calendarPage(range)
        #expect(h.calendarWriter.eventReads.count == reads + 1)
        #expect(h.calendarWriter.eventReads.last == range.interval)
    }

    @Test func deniedAccessReadsNothing() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        h.calendarWriter.eventsValue = [event("e1", day(2026, 3, 4, 9))]
        h.engine.calendarAccess = .denied
        let reads = h.calendarWriter.eventReads.count
        let data = h.engine.calendarPage(wednesday(h))
        #expect(h.calendarWriter.eventReads.count == reads)
        #expect(data.blocks.isEmpty)
        #expect(data.allDay.isEmpty)
        #expect(data.stats.planned == 0)
    }

    @Test func activityWithEventIDHidesItsEvent() {
        let row = Activity(text: "Write", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 10), calendarID: "work", eventID: "e1")
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 12), activities: [row])
        h.calendarWriter.eventsValue = [event("e1", day(2026, 3, 4, 9)), event("e2", day(2026, 3, 4, 11))]
        let data = h.engine.calendarPage(wednesday(h))
        #expect(data.blocks.map(\.title).sorted() == ["Write", "e2"])
        #expect(data.stats.planned == 2 * 60 * 60)
    }

    @Test func rowAfterMidnightIsInTheDayBefore() {
        let row = Activity(text: "Late", start: day(2026, 3, 5, 0, 22), end: day(2026, 3, 5, 2, 2))
        let h = EngineHarness.tracker(at: day(2026, 3, 5, 12), activities: [row])
        let data = h.engine.calendarPage(wednesday(h))
        #expect(data.blocks.map(\.title) == ["Late"])
        #expect(data.stats.tracked == 100 * 60)
    }

    @Test func sameEventKeyShowsOnce() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        let e = event("e1", day(2026, 3, 4, 9))
        h.calendarWriter.eventsValue = [e, e]
        let data = h.engine.calendarPage(wednesday(h))
        #expect(data.blocks.count == 1)
        #expect(Set(data.blocks.map(\.id)).count == data.blocks.count)
    }

    @Test func runningActivityShowsUntilNow() {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        h.engine.data.live.tracker.running = RunningActivity(
            text: "Focus", start: day(2026, 3, 4, 10), expectedLength: .minutes(60), askAt: day(2026, 3, 4, 11)
        )
        h.clock.advance(minutes: 20)
        let data = h.engine.calendarPage(wednesday(h))
        let block = data.blocks.first { $0.title == "Focus" }
        #expect(block?.interval.end == day(2026, 3, 4, 10, 20))
        #expect(data.stats.tracked == 20 * 60)
    }

    @Test func monthRangeHasCells() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        #expect(h.engine.calendarPage(wednesday(h)).monthCells.isEmpty)
        let month = h.engine.calendarPage(wednesday(h, kind: .month))
        #expect(month.monthCells.flatMap { $0 }.filter(\.isToday).map(\.day.raw) == ["2026-03-04"])
    }
}
