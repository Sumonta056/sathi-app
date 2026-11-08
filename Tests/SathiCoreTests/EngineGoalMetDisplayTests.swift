import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine goal met display")
struct EngineGoalMetDisplayTests {
    private func goal(_ id: HabitID) -> Double {
        switch id {
        case .water: return 8
        case .reading: return 15
        case .meditation: return 10
        case .gym: return 20
        }
    }

    private func turnOff(_ id: HabitID, _ prefs: inout Prefs) {
        switch id {
        case .water: prefs.water.enabled = false
        case .reading: prefs.reading.enabled = false
        case .meditation: prefs.meditation.enabled = false
        case .gym: prefs.gym.enabled = false
        }
    }

    private func harness(met id: HabitID, configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness {
            $0.prefs.water.enabled = true
            $0.prefs.reading.enabled = true
            $0.prefs.meditation.enabled = true
            $0.prefs.gym.enabled = true
            $0.live.gymMinutesSince = day(2026, 3, 4, 7)
            $0.events = [.done(id, goal(id), at: day(2026, 3, 4, 9, 45))]
            configure(&$0)
        }
    }

    @Test(arguments: HabitID.allCases)
    func goalMetIsTrueWhenTodaysTotalMeetsTheGoal(_ id: HabitID) {
        let h = harness(met: id)
        #expect(h.engine.goalMet(id))
    }

    @Test func goalMetIsFalseBelowTheGoal() {
        let h = EngineHarness()
        for _ in 0 ..< 7 {
            h.engine.logWater(1)
        }
        #expect(!h.engine.goalMet(.water))
        h.engine.logWater(1)
        #expect(h.engine.goalMet(.water))
        h.engine.logWater(1)
        #expect(h.engine.goalMet(.water))
    }

    @Test func aGoalOfZeroIsNeverMet() {
        let h = EngineHarness { $0.prefs.water.dailyGoalGlasses = 0 }
        #expect(!h.engine.goalMet(.water))
        h.engine.logWater(1)
        #expect(!h.engine.goalMet(.water))
    }

    @Test func yesterdaysTotalDoesNotMeetTodaysGoal() {
        let h = EngineHarness { $0.events = [.done(.water, 8, at: day(2026, 3, 3, 15))] }
        #expect(!h.engine.goalMet(.water))
    }

    @Test(arguments: HabitID.allCases)
    func pillSaysGoalMet(_ id: HabitID) {
        let h = harness(met: id)
        #expect(h.engine.pill(id) == "✓ Goal met")
    }

    @Test func pendingSnoozeWinsOverGoalMet() {
        let h = harness(met: .water)
        h.engine.trigger(.water)
        h.engine.snooze(.water)
        #expect(h.engine.pill(.water).hasPrefix("Snoozed"))
    }

    @Test func pillSaysGoalMetAfterTheEighthGlass() {
        let h = EngineHarness()
        for _ in 0 ..< 8 {
            h.engine.logWater(1)
        }
        h.engine.endCelebrate()
        #expect(h.engine.pill(.water) == "✓ Goal met")
    }

    @Test(arguments: HabitID.allCases)
    func offWinsOverGoalMet(_ id: HabitID) {
        let h = harness(met: id) { turnOff(id, &$0.prefs) }
        #expect(h.engine.pill(id) == "Off")
    }

    @Test(arguments: HabitID.allCases)
    func dayOffWinsOverGoalMet(_ id: HabitID) {
        let today = DayKey(day(2026, 3, 4), calendar: .current)
        let h = harness(met: id) { $0.prefs.setDays(id, HabitDays(weekdays: Set(Weekday.allCases), daysOff: [today])) }
        #expect(h.engine.pill(id) == "Day off")
    }

    @Test func pausedWinsOverGoalMet() {
        let h = harness(met: .water)
        h.engine.pause(hours: 1)
        #expect(h.engine.pill(.water) == "Paused")
    }

    @Test func dueNowWinsOverGoalMet() {
        let h = harness(met: .water)
        h.showReminder(.water)
        #expect(h.engine.pill(.water) == "Due now")
    }
}
