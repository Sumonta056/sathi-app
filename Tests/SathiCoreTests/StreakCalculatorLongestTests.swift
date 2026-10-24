import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("StreakCalculator longest")
struct StreakCalculatorLongestTests {
    private let zone = FixedZone.berlin
    private var today: Date { zone.date(2026, 4, 15, 12) }

    private func longest(_ events: [HistoryEvent], goal: Double = 8, reset: Date? = nil) -> Int {
        let store = InMemoryHistoryStore(events: events)
        return StreakCalculator(calendar: zone.calendar)
            .longest(.water, goal: goal, reset: reset, now: today) { store.events(from: $0.start, to: $0.end) }
    }

    private func run(_ count: Int, endingDaysAgo daysAgo: Int) -> [HistoryEvent] {
        zone.doneDays(.water, 8, count: count, endingAt: zone.adding(days: -daysAgo, to: today))
    }

    @Test func theLongestRunInsideTheLookbackWins() {
        #expect(longest(run(3, endingDaysAgo: 0) + run(5, endingDaysAgo: 100) + run(4, endingDaysAgo: 200)) == 5)
    }

    @Test func aRunAcrossMonthBoundariesCountsInFull() {
        #expect(longest(run(70, endingDaysAgo: 10) + run(2, endingDaysAgo: 0)) == 70)
    }

    @Test func aRunOlderThanTheLookbackIsIgnored() {
        #expect(longest(run(20, endingDaysAgo: Limits.longestStreakLookbackDays + 30) + run(3, endingDaysAgo: 0)) == 3)
    }

    @Test func aRunEndingYesterdayCounts() {
        #expect(longest(run(6, endingDaysAgo: 1)) == 6)
    }

    @Test func noMetDaysGivesZero() {
        #expect(longest([.done(.water, 7.75, at: today), .snooze(.water, at: today)]) == 0)
    }

    @Test func goalZeroGivesZero() {
        #expect(longest(run(5, endingDaysAgo: 0), goal: 0) == 0)
    }

    @Test func daysBeforeTheResetNeverCount() {
        let events = run(10, endingDaysAgo: 3) + run(2, endingDaysAgo: 0)
        #expect(longest(events, reset: zone.adding(days: -1, to: today)) == 1)
        #expect(longest(events, reset: zone.adding(days: -20, to: today)) == 10)
    }

    @Test func otherHabitsNeverCount() {
        #expect(longest(zone.doneDays(.reading, 30, count: 9, endingAt: today)) == 0)
    }
}
