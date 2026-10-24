import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ReportBuilder interval")
struct ReportBuilderIntervalTests {
    private let zone = FixedZone.berlin
    private var builder: ReportBuilder { ReportBuilder(calendar: zone.calendar) }

    @Test func dayRunsFromMidnightToTheNextMidnight() {
        let interval = builder.interval(.day, containing: zone.date(2026, 3, 4, 15, 30))
        #expect(interval == DateInterval(start: zone.date(2026, 3, 4), end: zone.date(2026, 3, 5)))
    }

    @Test func weekRunsFromMondayToTheNextMonday() {
        let interval = builder.interval(.week, containing: zone.date(2026, 3, 4, 15))
        #expect(interval == DateInterval(start: zone.date(2026, 3, 2), end: zone.date(2026, 3, 9)))
    }

    @Test(arguments: [1, 2, 7])
    func aSundayBelongsToTheWeekThatStartedTheMondayBefore(_ firstWeekday: Int) {
        let local = FixedZone("Europe/Berlin", firstWeekday: firstWeekday)
        let interval = ReportBuilder(calendar: local.calendar).interval(.week, containing: local.date(2026, 3, 8, 23))
        #expect(interval == DateInterval(start: local.date(2026, 3, 2), end: local.date(2026, 3, 9)))
    }

    @Test func mondayMidnightStartsANewWeek() {
        let interval = builder.interval(.week, containing: zone.date(2026, 3, 9))
        #expect(interval == DateInterval(start: zone.date(2026, 3, 9), end: zone.date(2026, 3, 16)))
    }

    @Test func monthRunsFromTheFirstToTheFirstOfTheNextMonth() {
        let interval = builder.interval(.month, containing: zone.date(2026, 3, 31, 23, 59))
        #expect(interval == DateInterval(start: zone.date(2026, 3, 1), end: zone.date(2026, 4, 1)))
    }

    @Test func februaryInALeapYearHas29Days() {
        let interval = builder.interval(.month, containing: zone.date(2028, 2, 15))
        #expect(interval == DateInterval(start: zone.date(2028, 2, 1), end: zone.date(2028, 3, 1)))
        let days = zone.calendar.dateComponents([.day], from: interval.start, to: interval.end).day
        #expect(days == 29)
    }

    @Test(arguments: [(3, 4, 3, 2), (10, 28, 10, 26)])
    func aDSTWeekInNewYorkStartsAtLocalMidnight(_ month: Int, _ dayOfMonth: Int, _ startMonth: Int, _ startDay: Int) {
        let ny = FixedZone.newYork
        let interval = ReportBuilder(calendar: ny.calendar).interval(.week, containing: ny.date(2026, month, dayOfMonth, 12))
        #expect(ny.wallClock(interval.start) == [2026, startMonth, startDay, 0, 0])
        #expect(interval.end == ny.adding(days: 7, to: interval.start))
        #expect(ny.wallClock(interval.end)[3 ... 4] == [0, 0])
    }

    @Test(arguments: [(3, 4), (10, 28)])
    func aDSTWeekInNewYorkHasSevenDayBucketsAtLocalMidnight(_ month: Int, _ dayOfMonth: Int) {
        let ny = FixedZone.newYork
        let report = ReportBuilder(calendar: ny.calendar)
            .build(.week, now: ny.date(2026, month, dayOfMonth, 12), events: [], prefs: Prefs())
        let buckets = report.habits.first?.buckets ?? []
        #expect(buckets.count == 7)
        #expect(buckets.allSatisfy { ny.wallClock($0.start)[3 ... 4] == [0, 0] })
        #expect(buckets.allSatisfy { ny.adding(days: 1, to: $0.start) == $0.end })
        #expect(buckets.first?.start == report.interval.start)
        #expect(buckets.last?.end == report.interval.end)
    }
}
