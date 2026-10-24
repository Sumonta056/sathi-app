import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Stats")
struct StatsTests {
    private let stats = Stats()
    private let today = day(2026, 3, 4, 12)

    private func goalDays(_ count: Int, endingAt end: Date) -> [HistoryEvent] {
        (0 ..< count).map { .done(.water, 8, at: end.addingTimeInterval(TimeInterval(-$0) * Timing.day)) }
    }

    @Test func glassesSumsOnlyThatDay() {
        let events: [HistoryEvent] = [
            .done(.water, 1, at: day(2026, 3, 4, 10)),
            .done(.water, 0.5, at: day(2026, 3, 4, 15)),
            .done(.water, 2, at: day(2026, 3, 5, 10)),
            .done(.reading, 15, at: day(2026, 3, 4, 22)),
            .snooze(.water, at: day(2026, 3, 4, 11))
        ]
        #expect(stats.total(.water, on: today, in: events) == 1.5)
    }

    @Test func readMinutesSumsOnlyThatDay() {
        let events: [HistoryEvent] = [
            .done(.reading, 15, at: day(2026, 3, 4, 22)),
            .done(.reading, 15, at: day(2026, 3, 3, 22)),
            .done(.water, 2, at: day(2026, 3, 4, 10))
        ]
        #expect(stats.total(.reading, on: today, in: events) == 15)
    }

    @Test func waterStreakCountsConsecutiveGoalDays() {
        var data = Persisted()
        data.events = goalDays(3, endingAt: today)
        #expect(stats.streak(.water, data: data, now: today) == 3)
    }

    @Test func streakSurvivesUnfinishedToday() {
        var data = Persisted()
        data.events = goalDays(2, endingAt: today.addingTimeInterval(-Timing.day))
        #expect(stats.streak(.water, data: data, now: today) == 2)
    }

    @Test func gapEndsTheStreak() {
        var data = Persisted()
        data.events = goalDays(1, endingAt: today) + goalDays(3, endingAt: today.addingTimeInterval(-2 * Timing.day))
        #expect(stats.streak(.water, data: data, now: today) == 1)
    }

    @Test func streakResetKeepsOnlyDaysAfterReset() {
        var data = Persisted()
        data.events = goalDays(3, endingAt: today)
        data.live.streakReset[HabitID.water.rawValue] = today.addingTimeInterval(-1)
        #expect(stats.streak(.water, data: data, now: today) == 1)
    }

    @Test func eventAtTheResetMomentDoesNotCount() {
        var data = Persisted()
        data.events = goalDays(1, endingAt: today)
        data.live.streakReset[HabitID.water.rawValue] = today
        #expect(stats.streak(.water, data: data, now: today) == 0)
    }

    @Test func readingStreakUsesSessionLength() {
        var data = Persisted()
        data.events = [.done(.reading, 10, at: today)]
        #expect(stats.streak(.reading, data: data, now: today) == 0)
        data.events.append(.done(.reading, 5, at: today))
        #expect(stats.streak(.reading, data: data, now: today) == 1)
    }

    @Test func snoozesAndSkipsNeverCountTowardTheStreak() {
        var data = Persisted()
        data.events = [.skip(.reading, at: today), .snooze(.reading, at: today), .done(.reading, 10, at: today)]
        #expect(stats.streak(.reading, data: data, now: today) == 0)
    }
}
