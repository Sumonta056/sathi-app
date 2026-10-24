import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine streak cache")
struct EngineStreakCacheTests {
    private let windowStart = day(2026, 1, 1)

    private func metDays(_ count: Int, endingAt end: Date) -> [HistoryEvent] {
        (0 ..< count).map { .done(.water, 8, at: Calendar.current.date(byAdding: .day, value: -$0, to: end)!) }
    }

    private func harness(_ days: Int) -> EngineHarness {
        let h = EngineHarness { $0.events = metDays(days, endingAt: day(2026, 3, 3, 12)) }
        h.history.clearRanges()
        return h
    }

    @Test func aStreakInsideTheWindowLoadsNothingFromHistory() {
        let h = harness(20)
        #expect(h.engine.streak(.water) == 20)
        #expect(h.history.ranges.isEmpty)
    }

    @Test func aLongStreakLoadsOnlyMonthsOlderThanTheWindow() {
        let h = harness(70)
        #expect(h.engine.streak(.water) == 70)
        #expect(!h.history.ranges.isEmpty)
        #expect(h.history.ranges.allSatisfy { $0.end <= windowStart })
    }

    @Test func longestStreakLoadsOnlyMonthsOlderThanTheWindow() {
        let h = harness(70)
        #expect(h.engine.longestStreak(.water) == 70)
        #expect(h.history.ranges.allSatisfy { $0.end <= windowStart })
    }

    @Test func changingTheNameKeepsTheCache() {
        let h = harness(70)
        _ = h.engine.streak(.water)
        _ = h.engine.longestStreak(.water)
        h.history.clearRanges()
        h.engine.data.prefs.general.name = "Asha"
        #expect(h.engine.streak(.water) == 70)
        #expect(h.engine.longestStreak(.water) == 70)
        #expect(h.history.ranges.isEmpty)
    }

    @Test func longestStreakIsCachedForTheDay() {
        let h = harness(70)
        _ = h.engine.longestStreak(.water)
        h.history.clearRanges()
        h.advance(minutes: 60)
        #expect(h.engine.longestStreak(.water) == 70)
        #expect(h.history.ranges.isEmpty)
    }

    @Test func loggingWaterClearsTheCache() {
        let h = harness(70)
        _ = h.engine.streak(.water)
        h.history.clearRanges()
        h.engine.logWater(1)
        #expect(h.engine.streak(.water) == 70)
        #expect(!h.history.ranges.isEmpty)
    }

    @Test func reachingTheGoalTodayRaisesTheStreak() {
        let h = EngineHarness { $0.prefs.water.dailyGoalGlasses = 1 }
        #expect(h.engine.streak(.water) == 0)
        h.engine.logWater(1)
        #expect(h.engine.streak(.water) == 1)
    }

    @Test func changingTheGoalClearsTheCache() {
        let h = harness(3)
        #expect(h.engine.streak(.water) == 3)
        #expect(h.engine.longestStreak(.water) == 3)
        h.engine.data.prefs.water.dailyGoalGlasses = 9
        #expect(h.engine.streak(.water) == 0)
        #expect(h.engine.longestStreak(.water) == 0)
    }

    @Test func aStreakResetClearsTheCache() {
        let h = harness(3)
        #expect(h.engine.streak(.water) == 3)
        h.engine.data.live.streakReset[HabitID.water.rawValue] = day(2026, 3, 4, 9)
        #expect(h.engine.streak(.water) == 0)
    }
}
