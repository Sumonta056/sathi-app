import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("CalendarPageRange week days")
struct CalendarPageRangeWeekDaysTests {
    private let zone = FixedZone("Asia/Dhaka")
    private var now: Date { zone.date(2026, 11, 18, 22, 27) }

    private func raws(_ days: [DayKey]) -> [String] { days.map(\.raw) }

    private func nov(_ days: ClosedRange<Int>) -> [String] {
        days.map { String(format: "2026-11-%02d", $0) }
    }

    private func week(_ date: Date, _ count: Int) -> CalendarPageRange {
        .containing(date, kind: .week, calendar: zone.calendar, weekDays: count)
    }

    @Test(arguments: [(3, 17, 19), (4, 16, 19), (5, 16, 20), (7, 14, 20)])
    func weekHoldsTheDaysAroundToday(_ count: Int, _ first: Int, _ last: Int) {
        let range = week(now, count)
        #expect(raws(range.days) == nov(first ... last))
        #expect(range.days.count == count)
        #expect(range.weekDays == count)
        #expect(range.kind == .week)
        #expect(range.interval.start == zone.date(2026, 11, first, 6))
        #expect(range.interval.end == zone.date(2026, 11, last + 1, 6))
        #expect(range.holds(now))
    }

    @Test(arguments: [(3, 17, 19), (4, 16, 19), (5, 16, 20), (7, 14, 20)])
    func halfPastOneOnThursdayStillCountsAsWednesday(_ count: Int, _ first: Int, _ last: Int) {
        let range = week(zone.date(2026, 11, 19, 1, 30), count)
        #expect(raws(range.days) == nov(first ... last))
    }

    @Test(arguments: [(3, 18, 20), (4, 17, 20), (5, 17, 21), (7, 14, 20)])
    func sixOnThursdayMorningCountsAsThursday(_ count: Int, _ first: Int, _ last: Int) {
        let range = week(zone.date(2026, 11, 19, 6), count)
        #expect(raws(range.days) == nov(first ... last))
    }

    @Test func sevenDaysIsTheSaturdayWeekAsBefore() {
        let old = CalendarPageRange.containing(now, kind: .week, calendar: zone.calendar)
        #expect(raws(old.days) == nov(14 ... 20))
        #expect(old.weekDays == 7)
        #expect(week(now, 7) == old)
    }

    @Test(arguments: [(3, 17, 19), (4, 16, 19), (5, 16, 20), (7, 14, 20)])
    func containingADayGivesTheSameDays(_ count: Int, _ first: Int, _ last: Int) throws {
        let key = try #require(DayKey(raw: "2026-11-18"))
        let range = CalendarPageRange.containing(day: key, kind: .week, calendar: zone.calendar, weekDays: count)
        #expect(raws(range.days) == nov(first ... last))
        #expect(range.weekDays == count)
    }

    @Test(arguments: [(3, 20, 22), (4, 20, 23), (5, 21, 25), (7, 21, 27)])
    func nextMovesByTheDayCount(_ count: Int, _ first: Int, _ last: Int) {
        let next = week(now, count).next
        #expect(raws(next.days) == nov(first ... last))
        #expect(next.weekDays == count)
        #expect(next.interval.start == zone.date(2026, 11, first, 6))
        #expect(next.interval.end == zone.date(2026, 11, last + 1, 6))
    }

    @Test(arguments: [(3, 14, 16), (4, 12, 15), (5, 11, 15), (7, 7, 13)])
    func previousMovesByTheDayCount(_ count: Int, _ first: Int, _ last: Int) {
        let previous = week(now, count).previous
        #expect(raws(previous.days) == nov(first ... last))
        #expect(previous.weekDays == count)
    }

    @Test(arguments: [3, 4, 5, 7])
    func nextThenPreviousComesBack(_ count: Int) {
        let range = week(now, count)
        #expect(range.next.previous == range)
        #expect(range.previous.previous.next.next == range)
    }

    @Test func fiveDaysCrossTheMonthEnd() {
        let range = week(zone.date(2026, 11, 30, 12), 5)
        #expect(raws(range.days) == ["2026-11-28", "2026-11-29", "2026-11-30", "2026-12-01", "2026-12-02"])
        #expect(raws(range.next.days) == ["2026-12-03", "2026-12-04", "2026-12-05", "2026-12-06", "2026-12-07"])
    }

    @Test(arguments: [3, 4, 5])
    func dayIgnoresTheDayCount(_ count: Int) {
        let range = CalendarPageRange.containing(now, kind: .day, calendar: zone.calendar, weekDays: count)
        #expect(raws(range.days) == ["2026-11-18"])
        #expect(raws(range.next.days) == ["2026-11-19"])
        #expect(raws(range.previous.days) == ["2026-11-17"])
    }

    @Test(arguments: [3, 4, 5])
    func monthIgnoresTheDayCount(_ count: Int) {
        let range = CalendarPageRange.containing(now, kind: .month, calendar: zone.calendar, weekDays: count)
        #expect(range.days.count == 30)
        #expect(range.days.first?.raw == "2026-11-01")
        #expect(range.next.days.first?.raw == "2026-12-01")
        #expect(range.next.days.count == 31)
    }

    @Test(arguments: [(3, 17, 19), (4, 16, 19), (5, 16, 20), (7, 14, 20)])
    func dayToWeekKeepsTheDayCount(_ count: Int, _ first: Int, _ last: Int) {
        let day = CalendarPageRange.containing(now, kind: .day, calendar: zone.calendar, weekDays: count)
        let range = day.changed(to: .week, now: now)
        #expect(raws(range.days) == nov(first ... last))
        #expect(range.weekDays == count)
    }

    @Test(arguments: [(3, 17, 19), (4, 16, 19), (5, 16, 20), (7, 14, 20)])
    func monthToWeekKeepsTheDayCount(_ count: Int, _ first: Int, _ last: Int) {
        let month = CalendarPageRange.containing(now, kind: .month, calendar: zone.calendar, weekDays: count)
        let range = month.changed(to: .week, now: now)
        #expect(raws(range.days) == nov(first ... last))
    }

    @Test func weekToDayAndBackKeepsTheDayCount() {
        let range = week(now, 4).changed(to: .day, now: now).changed(to: .week, now: now)
        #expect(raws(range.days) == nov(16 ... 19))
        #expect(range.weekDays == 4)
    }

    @Test(arguments: [3, 4, 5])
    func rangesWithDifferentDayCountsDiffer(_ count: Int) {
        #expect(week(now, count) != week(now, 7))
    }

    @Test(arguments: [ReportRange.day, .month])
    func dayAndMonthEqualityIgnoresTheDayCount(_ kind: ReportRange) {
        let ranges = [3, 4, 5, 7].map { CalendarPageRange.containing(now, kind: kind, calendar: zone.calendar, weekDays: $0) }
        #expect(ranges.allSatisfy { $0 == ranges[0] })
        #expect(ranges.map(\.weekDays) == [3, 4, 5, 7])
    }
}
