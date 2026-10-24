import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine menu")
struct EngineMenuTests {
    private func metDays(_ id: HabitID, _ count: Int, prefs: Prefs = Prefs()) -> [HistoryEvent] {
        let goal = max(1, id.rules(prefs).dailyGoal)
        let end = day(2026, 3, 3, 12)
        return (0 ..< count).map { .done(id, goal, at: Calendar.current.date(byAdding: .day, value: -$0, to: end)!) }
    }

    private func parts(_ g: GoalText) -> [String] { [g.done, g.rest] }

    @Test func greetingUsesTheNameFromPrefs() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) { $0.prefs.general.name = "Asha" }
        #expect(h.engine.greeting == "Good morning, Asha")
    }

    @Test func greetingReadsTheClock() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        h.advance(minutes: 8 * 60)
        #expect(h.engine.greeting == "Good evening, Mridul")
    }

    @Test func bestStreakIsTheHighestAmongEnabledHabits() {
        let h = EngineHarness { $0.events = metDays(.water, 3) + metDays(.reading, 5) }
        #expect(h.engine.streak(.water) == 3)
        #expect(h.engine.streak(.reading) == 5)
        #expect(h.engine.bestStreak == 5)
    }

    @Test func bestStreakIgnoresADisabledHabit() {
        let h = EngineHarness {
            $0.prefs.reading.enabled = false
            $0.events = metDays(.water, 3) + metDays(.reading, 7)
        }
        #expect(h.engine.bestStreak == 3)
    }

    @Test func bestStreakCountsAnEnabledMeditation() {
        var prefs = Prefs()
        prefs.meditation.enabled = true
        let h = EngineHarness {
            $0.prefs.meditation.enabled = true
            $0.events = metDays(.water, 2) + metDays(.meditation, 4, prefs: prefs)
        }
        #expect(h.engine.bestStreak == 4)
    }

    @Test func bestStreakIsZeroWhenAllHabitsAreOff() {
        let h = EngineHarness {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            $0.prefs.meditation.enabled = false
            $0.events = metDays(.water, 6) + metDays(.reading, 6)
        }
        #expect(h.engine.bestStreak == 0)
    }

    @Test func waterGoalTextCountsGlasses() {
        let h = EngineHarness()
        h.engine.logWater(1)
        h.engine.logWater(1)
        #expect(parts(h.engine.goalText(.water)) == ["2", "of 8 glasses"])
    }

    @Test func waterGoalTextUsesTheGoalFromPrefs() {
        let h = EngineHarness { $0.prefs.water.dailyGoalGlasses = 10 }
        #expect(parts(h.engine.goalText(.water)) == ["0", "of 10 glasses"])
    }

    @Test func readingGoalTextCapsDoneAtTheSessionLength() {
        let h = EngineHarness { $0.events = [.done(.reading, 40, at: day(2026, 3, 4, 8))] }
        #expect(parts(h.engine.goalText(.reading)) == ["15", "of 15 min"])
    }

    @Test func readingGoalTextShowsPartialMinutes() {
        let h = EngineHarness {
            $0.prefs.reading.sessionMinutes = 30
            $0.events = [.done(.reading, 12, at: day(2026, 3, 4, 8))]
        }
        #expect(parts(h.engine.goalText(.reading)) == ["12", "of 30 min"])
    }

    @Test func meditationGoalTextStartsAtZero() {
        let h = EngineHarness { $0.prefs.meditation.enabled = true }
        #expect(parts(h.engine.goalText(.meditation)) == ["0", "of 10 min"])
    }

    @Test func meditationGoalTextCapsDoneAtTheGoal() {
        let h = EngineHarness {
            $0.prefs.meditation.enabled = true
            $0.events = [.done(.meditation, 99, at: day(2026, 3, 4, 8))]
        }
        #expect(parts(h.engine.goalText(.meditation)) == ["10", "of 10 min"])
    }
}
