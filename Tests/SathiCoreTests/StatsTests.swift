import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Stats")
struct StatsTests {
    private let stats = Stats()
    private let today = day(2026, 3, 4, 12)

    private func goalDays(_ count: Int, endingAt end: Date) -> [DrinkEntry] {
        (0 ..< count).map { DrinkEntry(date: end.addingTimeInterval(TimeInterval(-$0) * Timing.day), glasses: 8) }
    }

    @Test func glassesSumsOnlyThatDay() {
        let drinks = [
            DrinkEntry(date: day(2026, 3, 4, 10), glasses: 1),
            DrinkEntry(date: day(2026, 3, 4, 15), glasses: 0.5),
            DrinkEntry(date: day(2026, 3, 5, 10), glasses: 2)
        ]
        #expect(stats.glasses(on: today, in: drinks) == 1.5)
    }

    @Test func readMinutesSumsOnlyThatDay() {
        let reads = [ReadEntry(date: day(2026, 3, 4, 22), minutes: 15), ReadEntry(date: day(2026, 3, 3, 22), minutes: 15)]
        #expect(stats.readMinutes(on: today, in: reads) == 15)
    }

    @Test func waterStreakCountsConsecutiveGoalDays() {
        var data = Persisted()
        data.drinks = goalDays(3, endingAt: today)
        #expect(stats.streak(.water, data: data, now: today) == 3)
    }

    @Test func streakSurvivesUnfinishedToday() {
        var data = Persisted()
        data.drinks = goalDays(2, endingAt: today.addingTimeInterval(-Timing.day))
        #expect(stats.streak(.water, data: data, now: today) == 2)
    }

    @Test func gapEndsTheStreak() {
        var data = Persisted()
        data.drinks = goalDays(1, endingAt: today) + goalDays(3, endingAt: today.addingTimeInterval(-2 * Timing.day))
        #expect(stats.streak(.water, data: data, now: today) == 1)
    }

    @Test func streakResetKeepsOnlyDaysAfterReset() {
        var data = Persisted()
        data.drinks = goalDays(3, endingAt: today)
        data.streakReset[HabitID.water.rawValue] = today.addingTimeInterval(-1)
        #expect(stats.streak(.water, data: data, now: today) == 1)
    }

    @Test func readingStreakUsesSessionLength() {
        var data = Persisted()
        data.reads = [ReadEntry(date: today, minutes: 10)]
        #expect(stats.streak(.reading, data: data, now: today) == 0)
        data.reads.append(ReadEntry(date: today, minutes: 5))
        #expect(stats.streak(.reading, data: data, now: today) == 1)
    }
}
