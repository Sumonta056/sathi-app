import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Goal met rule")
struct GoalMetRuleTests {
    private let zone = FixedZone.berlin
    private var now: Date { zone.date(2026, 3, 4, 11) }

    private func rules(_ id: HabitID, _ prefs: Prefs = Prefs()) -> any HabitRules {
        id.rules(prefs, calendar: zone.calendar)
    }

    private func firstReminder(_ id: HabitID) -> [Int] {
        switch id {
        case .water: return [9, 30]
        case .reading: return [22, 0]
        case .meditation: return [9, 0]
        case .gym: return [10, 0]
        }
    }

    private func due(_ id: HabitID, _ prefs: Prefs = Prefs(), done: Double, skip: Bool = false) -> [Int] {
        zone.wallClock(rules(id, prefs).nextDue(now: now, lastDone: now, doneToday: done, skipToday: skip))
    }

    @Test(arguments: HabitID.allCases)
    func metGoalWaitsForTheFirstReminderOfTomorrow(_ id: HabitID) {
        let goal = rules(id).dailyGoal
        #expect(due(id, done: goal) == [2026, 3, 5] + firstReminder(id))
    }

    @Test(arguments: HabitID.allCases)
    func goalExceededWaitsForTheFirstReminderOfTomorrow(_ id: HabitID) {
        let goal = rules(id).dailyGoal
        #expect(due(id, done: goal + 3) == [2026, 3, 5] + firstReminder(id))
    }

    @Test(arguments: HabitID.allCases)
    func skipTodayWaitsForTheFirstReminderOfTomorrow(_ id: HabitID) {
        #expect(due(id, done: 0, skip: true) == [2026, 3, 5] + firstReminder(id))
    }

    @Test(arguments: HabitID.allCases)
    func metGoalSkipsTomorrowWhenTomorrowIsOff(_ id: HabitID) {
        var prefs = Prefs()
        prefs.setDays(id, HabitDays(weekdays: Set(Weekday.allCases).subtracting([.thursday]), daysOff: []))
        let goal = rules(id, prefs).dailyGoal
        #expect(due(id, prefs, done: goal) == [2026, 3, 6] + firstReminder(id))
    }

    @Test(arguments: [(HabitID.water, [2026, 3, 4, 13, 0]), (HabitID.meditation, [2026, 3, 4, 12, 0])])
    func justBelowTheGoalKeepsTheIntervalToday(_ id: HabitID, _ expected: [Int]) {
        let goal = rules(id).dailyGoal
        #expect(due(id, done: goal - 1) == expected)
    }

    @Test func waterGoalOfZeroNeverCountsAsMet() {
        var prefs = Prefs()
        prefs.water.dailyGoalGlasses = 0
        #expect(due(.water, prefs, done: 0) == [2026, 3, 4, 13, 0])
    }
}
