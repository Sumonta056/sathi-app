import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Stats range")
struct StatsRangeTests {
    private let zone = FixedZone.berlin

    private func range(_ kind: ReportRange, _ date: Date, firstWeekday: Int = 2) -> StatsRange {
        let fixed = FixedZone("Europe/Berlin", firstWeekday: firstWeekday)
        return StatsRange.containing(date, kind: kind, calendar: fixed.calendar)
    }

    @Test func dayRunsMidnightToMidnight() {
        let r = range(.day, zone.date(2025, 11, 11, 14, 52))
        #expect(r.interval.start == zone.date(2025, 11, 11))
        #expect(r.interval.end == zone.date(2025, 11, 12))
        #expect(r.kind == .day)
    }

    @Test func monthRunsFirstToFirst() {
        let r = range(.month, zone.date(2025, 11, 11, 14, 52))
        #expect(r.interval.start == zone.date(2025, 11, 1))
        #expect(r.interval.end == zone.date(2025, 12, 1))
    }

    @Test(arguments: [(2, 10), (1, 9)])
    func weekStartsOnFirstWeekday(first: Int, startDay: Int) {
        let r = range(.week, zone.date(2025, 11, 11, 14, 52), firstWeekday: first)
        #expect(r.interval.start == zone.date(2025, 11, startDay))
        #expect(r.interval.end == zone.date(2025, 11, startDay + 7))
    }

    @Test func weekHoldingItsFirstDayStaysPut() {
        let r = range(.week, zone.date(2025, 11, 10, 9, 0))
        #expect(r.interval.start == zone.date(2025, 11, 10))
    }

    @Test func previousAndNextCrossAMonth() {
        let r = range(.month, zone.date(2025, 12, 5))
        #expect(r.previous.interval.start == zone.date(2025, 11, 1))
        #expect(r.next.interval.start == zone.date(2026, 1, 1))
        #expect(r.previous.next == r)
    }

    @Test func previousAndNextCrossAYear() {
        let week = range(.week, zone.date(2025, 12, 31))
        #expect(week.next.interval.start == zone.date(2026, 1, 5))
        #expect(week.previous.interval.start == zone.date(2025, 12, 22))
        let day = range(.day, zone.date(2026, 1, 1))
        #expect(day.previous.interval.start == zone.date(2025, 12, 31))
    }

    @Test func holdsIsHalfOpen() {
        let r = range(.day, zone.date(2025, 11, 11))
        #expect(r.holds(zone.date(2025, 11, 11)))
        #expect(r.holds(zone.date(2025, 11, 11, 23, 59)))
        #expect(!r.holds(zone.date(2025, 11, 12)))
    }

    @Test func forwardIsOffOnTheRangeHoldingNow() {
        let now = zone.date(2025, 11, 11, 14, 52)
        let current = range(.week, now)
        #expect(!current.canGoForward(now: now))
        #expect(current.previous.canGoForward(now: now))
    }

    @Test func changingKindKeepsTheFirstDay() {
        let now = zone.date(2025, 11, 11, 14, 52)
        let week = range(.week, zone.date(2025, 10, 22)).previous
        let month = week.changed(to: .month, now: now)
        #expect(month.kind == .month)
        #expect(month.interval.start == zone.date(2025, 10, 1))
        let day = week.changed(to: .day, now: now)
        #expect(day.interval.start == week.interval.start)
    }

    @Test func changingKindOnTheRangeHoldingNowJumpsToToday() {
        let now = zone.date(2025, 11, 11, 14, 52)
        let week = range(.week, now)
        let day = week.changed(to: .day, now: now)
        #expect(day.interval.start == zone.date(2025, 11, 11))
        #expect(week.changed(to: .month, now: now).interval.start == zone.date(2025, 11, 1))
    }

    @Test func daysListsEveryDayOfTheRange() {
        let r = range(.week, zone.date(2025, 11, 11))
        #expect(r.days.count == 7)
        #expect(r.days.first?.start == zone.date(2025, 11, 10))
        #expect(r.days.last?.end == zone.date(2025, 11, 17))
        #expect(range(.month, zone.date(2025, 11, 11)).days.count == 30)
    }

    @Test func dstWeekHasSevenDaysStartingAtMidnight() {
        let r = range(.week, zone.date(2025, 10, 22))
        #expect(r.days.count == 7)
        #expect(r.days.allSatisfy { $0.start == zone.calendar.startOfDay(for: $0.start) })
        #expect(r.days.map(\.duration).contains(25 * 3600))
        let spring = range(.week, zone.date(2025, 3, 26))
        #expect(spring.days.count == 7)
        #expect(spring.days.allSatisfy { $0.start == zone.calendar.startOfDay(for: $0.start) })
    }
}
