import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Streak window")
struct StreakWindowTests {
    private let zone = FixedZone.berlin

    private func streaks(_ days: Int, now: Date) -> (current: Int, longest: Int) {
        let store = InMemoryHistoryStore(events: zone.doneDays(.water, 8, count: days, endingAt: now))
        let load: (DateInterval) -> [HistoryEvent] = { store.events(from: $0.start, to: $0.end) }
        let s = StreakCalculator(calendar: zone.calendar)
        return (s.current(.water, goal: 8, reset: nil, now: now, load: load), s.longest(.water, goal: 8, reset: nil, now: now, load: load))
    }

    @Test func fourHundredMetDaysCountAsTheLookbackDays() {
        let result = streaks(400, now: zone.date(2026, 4, 15, 12))
        #expect(result.current == Limits.streakLookbackDays)
        #expect(result.longest == Limits.streakLookbackDays)
        #expect(Limits.streakLookbackDays == 365)
    }

    @Test(arguments: [364, 365, 366, 400])
    func currentNeverExceedsLongest(_ days: Int) {
        let result = streaks(days, now: zone.date(2026, 4, 15, 12))
        #expect(result.current <= result.longest)
        #expect(result.current == min(days, 365))
    }
}
