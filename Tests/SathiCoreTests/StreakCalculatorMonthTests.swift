import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("StreakCalculator months")
struct StreakCalculatorMonthTests {
    private let zone = FixedZone.berlin

    private func run(_ events: [HistoryEvent], now: Date, reset: Date? = nil) -> (streak: Int, months: [String], store: InMemoryHistoryStore) {
        let store = InMemoryHistoryStore(events: events)
        let streak = StreakCalculator(calendar: zone.calendar)
            .current(.water, goal: 8, reset: reset, now: now) { store.events(from: $0.start, to: $0.end) }
        return (streak, store.ranges.map { zone.monthLabel($0.start) }, store)
    }

    private func staysInsideOneMonth(_ interval: DateInterval) -> Bool {
        guard let month = zone.calendar.dateInterval(of: .month, for: interval.start) else { return false }
        return interval.start >= month.start && interval.end <= month.end
    }

    @Test func aStreakAcrossTwoMonthBoundariesIsCountedInFull() {
        let now = zone.date(2026, 4, 15, 12)
        let result = run(zone.doneDays(.water, 8, count: 70, endingAt: now), now: now)
        #expect(result.streak == 70)
    }

    @Test func eachNeededMonthLoadsOnceNewestFirst() {
        let now = zone.date(2026, 4, 15, 12)
        let result = run(zone.doneDays(.water, 8, count: 70, endingAt: now), now: now)
        #expect(result.months == ["2026-04", "2026-03", "2026-02"])
        #expect(result.store.ranges.allSatisfy(staysInsideOneMonth))
    }

    @Test func aStreakAcrossADSTChangeCountsEveryCalendarDay() {
        let now = zone.date(2026, 4, 2, 0, 30)
        let events = zone.doneDays(.water, 8, count: 10, endingAt: now)
        #expect(run(events, now: now).streak == 10)
    }

    @Test func theWalkLoadsTheMonthOfTheDayItStoppedOn() {
        let now = zone.date(2026, 4, 3, 12)
        let result = run(zone.doneDays(.water, 8, count: 3, endingAt: now), now: now)
        #expect(result.streak == 3)
        #expect(result.months == ["2026-04", "2026-03"])
    }

    @Test func theWalkNeverLoadsAnOlderMonthThanTheStopDay() {
        let now = zone.date(2026, 4, 15, 12)
        let old = zone.doneDays(.water, 8, count: 30, endingAt: zone.date(2026, 3, 31, 12))
        let result = run(old + zone.doneDays(.water, 8, count: 1, endingAt: now), now: now)
        #expect(result.streak == 1)
        #expect(result.months == ["2026-04"])
    }

    @Test func todayAndYesterdayNotMetLoadsOnlyWhatTheWalkNeeds() {
        let now = zone.date(2026, 4, 1, 12)
        let result = run(zone.doneDays(.water, 8, count: 5, endingAt: zone.date(2026, 3, 30, 12)), now: now)
        #expect(result.streak == 0)
        #expect(result.months == ["2026-04", "2026-03"])
    }

    @Test func theWalkStopsAfterTheLookbackDays() {
        let now = zone.date(2026, 4, 15, 12)
        let events = zone.doneDays(.water, 8, count: Limits.streakLookbackDays + 40, endingAt: now)
        #expect(run(events, now: now).streak == Limits.streakLookbackDays)
    }

    @Test func aResetInAnOlderMonthStopsTheWalkThere() {
        let now = zone.date(2026, 4, 15, 12)
        let events = zone.doneDays(.water, 8, count: 70, endingAt: now)
        let result = run(events, now: now, reset: zone.date(2026, 3, 10, 12))
        #expect(result.streak == 36)
        #expect(result.months == ["2026-04", "2026-03"])
    }
}
