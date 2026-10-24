import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine reports")
struct EngineReportTests {
    private func daysBefore(_ count: Int, _ date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -count, to: date)!
    }

    private func metDays(_ count: Int, endingAt end: Date, amount: Double = 8) -> [HistoryEvent] {
        (0 ..< count).map { .done(.water, amount, at: daysBefore($0, end)) }
    }

    @Test func streakCountsSeventyMetDaysBeyondTheMemoryWindow() {
        let h = EngineHarness { $0.events = metDays(70, endingAt: day(2026, 3, 3, 12)) }
        #expect(h.engine.streak(.water) == 70)
    }

    @Test func streakUsesTheStreakResetFromLiveState() {
        let h = EngineHarness {
            $0.events = metDays(70, endingAt: day(2026, 3, 3, 12))
            $0.live.streakReset[HabitID.water.rawValue] = day(2025, 12, 28, 12)
        }
        #expect(h.engine.streak(.water) == 65)
    }

    @Test func weekReportUsesTheHistoryStore() throws {
        let h = EngineHarness()
        h.history.append(.done(.water, 3, at: day(2026, 3, 2, 10)))
        h.history.append(.snooze(.water, at: day(2026, 3, 3, 11)))
        h.engine.logWater(2)
        h.history.clearRanges()
        let report = h.engine.report(.week)
        let interval = DateInterval(start: day(2026, 3, 2), end: day(2026, 3, 9))
        #expect(report.range == .week)
        #expect(report.interval == interval)
        #expect(h.history.ranges == [interval])
        let water = try #require(report.habits.first { $0.habit == .water })
        #expect(water.total == 5)
        #expect(water.snoozes == 1)
        #expect(water.buckets[0].total == 3)
        #expect(water.buckets[2].total == 2)
    }

    @Test func reportUsesTheCurrentPrefs() {
        let h = EngineHarness()
        h.engine.data.prefs.water.dailyGoalGlasses = 10
        #expect(h.engine.report(.day).habits.first?.goal == 10)
    }

    @Test(arguments: [ReportRange.day, .week, .month])
    func reportIntervalContainsNow(_ range: ReportRange) {
        let h = EngineHarness()
        h.advance(minutes: 60)
        let report = h.engine.report(range)
        #expect(report.range == range)
        #expect(report.interval.start <= h.clock.now && h.clock.now < report.interval.end)
    }

    @Test func longestStreakFindsAnOlderLongerRun() {
        let h = EngineHarness {
            $0.events = metDays(40, endingAt: day(2025, 12, 1, 12)) + metDays(5, endingAt: day(2026, 3, 3, 12))
        }
        #expect(h.engine.streak(.water) == 5)
        #expect(h.engine.longestStreak(.water) == 40)
    }

    @Test func longestStreakIsZeroWithoutHistory() {
        #expect(EngineHarness().engine.longestStreak(.reading) == 0)
    }
}
