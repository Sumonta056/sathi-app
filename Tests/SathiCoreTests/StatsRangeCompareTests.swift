import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Stats range compare")
struct StatsRangeCompareTests {
    private let zone = FixedZone.berlin

    private func range(_ kind: ReportRange, _ date: Date) -> StatsRange {
        StatsRange.containing(date, kind: kind, calendar: zone.calendar)
    }

    @Test func currentWeekCutsLastWeekAtTheSameDayAndClock() {
        let now = zone.date(2025, 11, 11, 14, 52)
        let cut = range(.week, now).comparable(now: now, calendar: zone.calendar)
        #expect(cut.start == zone.date(2025, 11, 3))
        #expect(cut.end == zone.date(2025, 11, 4, 14, 52))
    }

    @Test func pastRangeComparesWhole() {
        let now = zone.date(2025, 11, 20, 9, 0)
        let past = range(.week, zone.date(2025, 11, 11))
        let cut = past.comparable(now: now, calendar: zone.calendar)
        #expect(cut == past.previous.interval)
    }

    @Test func longMonthAgainstShortMonthStopsAtThePreviousEnd() {
        let now = zone.date(2025, 12, 31, 18, 30)
        let cut = range(.month, now).comparable(now: now, calendar: zone.calendar)
        #expect(cut.start == zone.date(2025, 11, 1))
        #expect(cut.end == zone.date(2025, 12, 1))
    }

    @Test func monthCutKeepsWholeDaysPlusClock() {
        let now = zone.date(2025, 12, 10, 8, 15)
        let cut = range(.month, now).comparable(now: now, calendar: zone.calendar)
        #expect(cut.end == zone.date(2025, 11, 10, 8, 15))
    }

    @Test func dayComparesWithYesterdayAtTheSameClock() {
        let now = zone.date(2025, 11, 11, 14, 52)
        let cut = range(.day, now).comparable(now: now, calendar: zone.calendar)
        #expect(cut.start == zone.date(2025, 11, 10))
        #expect(cut.end == zone.date(2025, 11, 10, 14, 52))
    }

    @Test func firstSecondOfARangeCutsToItsStart() {
        let now = zone.date(2025, 11, 10)
        let cut = range(.week, now).comparable(now: now, calendar: zone.calendar)
        #expect(cut.start == zone.date(2025, 11, 3))
        #expect(cut.end == cut.start)
    }
}
