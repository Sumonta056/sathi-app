import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Midnight DST")
struct MidnightDSTTests {
    private let zone = FixedZone.cairo

    private func startOfDay(_ y: Int, _ m: Int, _ d: Int) -> Date {
        zone.calendar.startOfDay(for: zone.date(y, m, d, 12))
    }

    private func week(_ events: [HistoryEvent]) -> HabitReport? {
        ReportBuilder(calendar: zone.calendar)
            .build(.week, now: zone.date(2026, 4, 26, 12), events: events, prefs: Prefs())
            .habits.first { $0.habit == .water }
    }

    @Test func theDSTDayStartsAtOneAndLaterDaysAtMidnight() {
        #expect(zone.wallClock(startOfDay(2026, 4, 24))[3 ... 4] == [1, 0])
        #expect(zone.wallClock(startOfDay(2026, 4, 25))[3 ... 4] == [0, 0])
    }

    @Test func aStreakAcrossTheChangeCountsEveryDay() {
        let now = zone.date(2026, 4, 28, 12)
        let store = InMemoryHistoryStore(events: zone.doneDays(.water, 8, count: 10, endingAt: now))
        let load: (DateInterval) -> [HistoryEvent] = { store.events(from: $0.start, to: $0.end) }
        let streaks = StreakCalculator(calendar: zone.calendar)
        #expect(streaks.current(.water, goal: 8, reset: nil, now: now, load: load) == 10)
        #expect(streaks.longest(.water, goal: 8, reset: nil, now: now, load: load) == 10)
    }

    @Test func theWeekHasSevenBucketsAtEachDaysStart() throws {
        let buckets = try #require(week([])?.buckets)
        #expect(buckets.count == 7)
        #expect(buckets.map(\.start) == (20 ... 26).map { startOfDay(2026, 4, $0) })
        #expect(buckets.map(\.end) == (21 ... 27).map { startOfDay(2026, 4, $0) })
    }

    @Test func theDayBeforeTheChangeEndsAtTheStartOfTheNextDay() {
        let interval = ReportBuilder(calendar: zone.calendar).interval(.day, containing: zone.date(2026, 4, 23, 12))
        #expect(interval == DateInterval(start: startOfDay(2026, 4, 23), end: startOfDay(2026, 4, 24)))
    }

    @Test func anEventJustAfterMidnightOnSaturdayIsInSaturdaysBucket() throws {
        let buckets = try #require(week([.done(.water, 2, at: zone.date(2026, 4, 25, 0, 30))])?.buckets)
        #expect(buckets.map(\.total) == [0, 0, 0, 0, 0, 2, 0])
    }

    @Test func aSaturdayJustAfterMidnightIsTheBestDay() {
        #expect(week([.done(.water, 2, at: zone.date(2026, 4, 25, 0, 30))])?.bestDay == startOfDay(2026, 4, 25))
    }
}
