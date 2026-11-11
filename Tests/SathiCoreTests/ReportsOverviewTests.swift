import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Reports overview")
struct ReportsOverviewTests {
    nonisolated static let now = day(2026, 11, 11, 20)

    nonisolated static func week() -> StatsRange {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return StatsRange.containing(now, kind: .week, calendar: calendar)
    }

    static func harness(daysOff: Bool = false) -> EngineHarness {
        EngineHarness(at: now) {
            $0.prefs.water.dailyGoalGlasses = 8
            $0.prefs.reading.sessionMinutes = 15
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.dailyGoalMinutes = 10
            $0.prefs.gym.enabled = true
            $0.prefs.gym.sessionsPerDay = 2
            $0.prefs.gym.sessionMinutes = 5
            $0.live.gymMinutesSince = day(2026, 1, 1)
            if daysOff {
                let off: Set<DayKey> = [DayKey(day(2026, 11, 10), calendar: .current)]
                $0.prefs.reading.daysOff = off
                $0.prefs.gym.daysOff = off
            }
            $0.events = [
                .done(.water, 8, at: day(2026, 11, 9, 9)),
                .done(.water, 8, at: day(2026, 11, 10, 9)),
                .done(.water, 3, at: day(2026, 11, 11, 9)),
                .done(.reading, 15, at: day(2026, 11, 9, 10)),
                .done(.reading, 5, at: day(2026, 11, 10, 10)),
                .done(.meditation, 10, at: day(2026, 11, 9, 11)),
                .done(.meditation, 10, at: day(2026, 11, 10, 11)),
                .done(.meditation, 10, at: day(2026, 11, 11, 11)),
                .done(.gym, 10, at: day(2026, 11, 9, 12)),
                .done(.water, 8, at: day(2026, 11, 3, 9))
            ]
        }
    }

    @Test func theScoreCountsGoalsMetOfEveryBuddyTimesEveryDay() {
        let score = Self.harness().engine.reportsOverview(Self.week()).score
        #expect(score.met == 7)
        #expect(score.possible == 28)
        #expect(score.label == "WEEK SCORE · 3 DAYS SO FAR")
    }

    @Test func eachBuddyHasItsGoalDaysOfTheDaysInTheRange() {
        let scores = Self.harness().engine.reportsOverview(Self.week()).scores
        #expect(scores.map(\.met) == [2, 1, 3, 1])
        #expect(scores.map(\.days) == [7, 7, 7, 7])
        #expect(scores.map(\.counted) == [3, 3, 3, 3])
    }

    @Test func theHeadlineNamesTheBestAndTheWeakestBuddy() {
        let score = Self.harness().engine.reportsOverview(Self.week()).score
        #expect(score.headline == "Good week. Shanti leads, Shokti needs a push.")
    }

    @Test func theChangeLineComparesGoalsWithTheSameDaysLastWeek() {
        let score = Self.harness().engine.reportsOverview(Self.week()).score
        #expect(score.changeText == "+6 goals vs the same days last week · streak 0 days")
        #expect(score.isUp)
    }

    @Test func theGridHasOneColumnPerDayAndOneRowPerOnBuddy() {
        let overview = Self.harness().engine.reportsOverview(Self.week())
        #expect(overview.columns.map(\.label).prefix(3) == ["Mon 9", "Tue 10", "Wed 11"])
        #expect(overview.columns[2].isToday)
        #expect(overview.columns[3].isFuture)
        #expect(overview.rows.map(\.habit) == [.water, .reading, .meditation, .gym])
        let water = overview.rows[0].cells
        #expect(water.map(\.text).prefix(4) == ["8", "8", "3", ""])
        #expect(water.map(\.state).prefix(4) == [.met, .met, .some, .future])
        let gym = overview.rows[3].cells
        #expect(gym[1].text == "0m")
        #expect(gym[1].state == BuddyDayState.none)
    }

    @Test func aDayOffShowsOffAndNeverBreaksTheStreak() {
        let overview = Self.harness(daysOff: true).engine.reportsOverview(Self.week())
        #expect(overview.rows[3].cells[1].text == "Off")
        #expect(overview.rows[3].cells[1].state == .off)
        #expect(overview.streak == 2)
    }

    @Test func anOffBuddyHasNoRowAndIsMarkedOff() {
        let h = EngineHarness(at: Self.now)
        let overview = h.engine.reportsOverview(Self.week())
        #expect(overview.rows.map(\.habit) == [.water, .reading])
        #expect(overview.scores.filter(\.isOff).map(\.habit) == [.meditation, .gym])
        #expect(overview.score.possible == 14)
    }

    @Test func aPastWeekSaysDaysWithoutSoFar() {
        let range = Self.week().previous
        let score = Self.harness().engine.reportsOverview(range).score
        #expect(score.label == "WEEK SCORE · 7 DAYS")
        #expect(score.changeText.hasPrefix("+1 goal vs last week"))
    }
}
