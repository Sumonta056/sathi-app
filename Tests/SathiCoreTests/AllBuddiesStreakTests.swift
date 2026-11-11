import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("All buddies streak")
struct AllBuddiesStreakTests {
    private func waterOnly(at now: Date, configure: (inout Persisted) -> Void) -> EngineHarness {
        EngineHarness(at: now) {
            $0.prefs.reading.enabled = false
            configure(&$0)
        }
    }

    @Test func aStreakResetIsHonored() {
        let h = waterOnly(at: day(2026, 11, 11, 20)) {
            $0.events = [9, 10, 11].map { .done(.water, 8, at: day(2026, 11, $0, 9)) }
            $0.live.streakReset[HabitID.water.rawValue] = day(2026, 11, 10, 12)
        }
        #expect(h.engine.allBuddiesStreak() == 1)
    }

    @Test func anAllOffStretchIsSkippedAndAnOnDayWithNoEventsBreaks() {
        let h = waterOnly(at: day(2026, 11, 16, 20)) {
            $0.prefs.water.weekdays = [.monday, .tuesday, .wednesday, .thursday]
            $0.events = [11, 12].map { .done(.water, 8, at: day(2026, 11, $0, 9)) }
        }
        #expect(h.engine.allBuddiesStreak() == 2)
    }

    @Test func twoReadsInTheSameDayComputeOnce() {
        let h = waterOnly(at: day(2026, 11, 11, 20)) {
            $0.events = [10, 11].map { .done(.water, 8, at: day(2026, 11, $0, 9)) }
        }
        #expect(h.engine.allBuddiesStreak() == 2)
        h.engine.allStreakCache?.value = 99
        let month = StatsRange.containing(h.clock.now, kind: .month, calendar: h.engine.calendar)
        #expect(h.engine.allBuddiesStreak() == 99)
        #expect(h.engine.streakOverview(month).streakText == "Streak 99 days")
        #expect(h.engine.reportsOverview(StatsRange.containing(h.clock.now, kind: .week, calendar: h.engine.calendar)).streak == 99)
    }

    @Test func aDataChangeOrANewDayComputesAgain() {
        let h = waterOnly(at: day(2026, 11, 11, 20)) {
            $0.events = [10, 11].map { .done(.water, 8, at: day(2026, 11, $0, 9)) }
        }
        _ = h.engine.allBuddiesStreak()
        h.engine.allStreakCache?.value = 99
        h.engine.data.events.append(.done(.water, 1, at: day(2026, 11, 11, 19)))
        #expect(h.engine.allBuddiesStreak() == 2)
        h.engine.allStreakCache?.value = 99
        h.clock.now = day(2026, 11, 12, 9)
        #expect(h.engine.allBuddiesStreak() == 2)
    }

    private func cached(_ h: EngineHarness) {
        _ = h.engine.allBuddiesStreak()
        h.engine.allStreakCache?.value = 99
    }

    @Test func aNewDoneEventRebuildsTheCache() {
        let h = waterOnly(at: day(2026, 11, 11, 20)) {
            $0.events = [10, 11].map { .done(.water, 8, at: day(2026, 11, $0, 9)) }
        }
        cached(h)
        #expect(h.engine.allBuddiesStreak() == 99)
        h.engine.data.events.append(.done(.water, 1, at: day(2026, 11, 11, 19)))
        #expect(h.engine.allBuddiesStreak() == 2)
    }

    @Test func aGoalChangeRebuildsTheCache() {
        let h = waterOnly(at: day(2026, 11, 11, 20)) {
            $0.events = [10, 11].map { .done(.water, 8, at: day(2026, 11, $0, 9)) }
        }
        cached(h)
        h.engine.data.prefs.water.dailyGoalGlasses = 9
        #expect(h.engine.allBuddiesStreak() == 0)
    }

    @Test func aNewDayRebuildsTheCache() {
        let h = waterOnly(at: day(2026, 11, 11, 20)) {
            $0.events = [10, 11].map { .done(.water, 8, at: day(2026, 11, $0, 9)) }
        }
        cached(h)
        h.clock.now = day(2026, 11, 12, 9)
        #expect(h.engine.allBuddiesStreak() == 2)
    }
}
