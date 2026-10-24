import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("WaterRules")
struct WaterRulesTests {
    private let rules = WaterRules(prefs: Prefs())

    private func due(after base: Date) -> Date {
        rules.nextDue(now: base, lastDone: base, doneToday: 0, skipToday: false)
    }

    @Test func idIsWater() {
        #expect(rules.id == .water)
    }

    @Test func nextDueInsideHours() {
        #expect(due(after: day(2026, 3, 4, 10)) == day(2026, 3, 4, 12))
    }

    @Test func nextDueBeforeStartSnapsToStart() {
        #expect(due(after: day(2026, 3, 4, 5)) == day(2026, 3, 4, 9, 30))
    }

    @Test func nextDueAfterEndMovesToNextMorning() {
        #expect(due(after: day(2026, 3, 4, 17)) == day(2026, 3, 5, 9, 30))
    }

    @Test func nextDueStartsFromLastDoneNotNow() {
        let next = rules.nextDue(now: day(2026, 3, 4, 12, 30), lastDone: day(2026, 3, 4, 11), doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 13))
    }

    @Test func nextDueWithoutLastDoneStartsFromNow() {
        let next = rules.nextDue(now: day(2026, 3, 4, 10), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 12))
    }

    @Test func nextDueIgnoresDoneTodayAndSkip() {
        let next = rules.nextDue(now: day(2026, 3, 4, 10), lastDone: nil, doneToday: 20, skipToday: true)
        #expect(next == day(2026, 3, 4, 12))
    }

    @Test func nextDueFollowsTheInterval() {
        var prefs = Prefs()
        prefs.water.intervalMinutes = 30
        let next = WaterRules(prefs: prefs).nextDue(now: day(2026, 3, 4, 10), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 10, 30))
    }

    @Test func isActiveTimeBoundaries() {
        #expect(!rules.isActiveTime(day(2026, 3, 4, 9, 29)))
        #expect(rules.isActiveTime(day(2026, 3, 4, 9, 30)))
        #expect(rules.isActiveTime(day(2026, 3, 4, 18, 29)))
        #expect(!rules.isActiveTime(day(2026, 3, 4, 18, 30)))
    }

    @Test func nextActiveStart() {
        #expect(rules.nextActiveStart(after: day(2026, 3, 4, 6)) == day(2026, 3, 4, 9, 30))
        #expect(rules.nextActiveStart(after: day(2026, 3, 4, 20)) == day(2026, 3, 5, 9, 30))
    }

    @Test func dailyGoalIsGlassGoal() {
        #expect(rules.dailyGoal == 8)
        var prefs = Prefs()
        prefs.water.dailyGoalGlasses = 6
        #expect(WaterRules(prefs: prefs).dailyGoal == 6)
    }

    @Test func totalSumsOnlyThatDaysDrinks() {
        var data = Persisted()
        data.events = [
            .done(.water, 4, at: day(2026, 3, 3, 23, 59)),
            .done(.water, 1, at: day(2026, 3, 4, 0, 1)),
            .done(.water, 1.5, at: day(2026, 3, 4, 14)),
            .done(.water, 2, at: day(2026, 3, 5, 9)),
            .done(.reading, 15, at: day(2026, 3, 4, 22)),
            .snooze(.water, at: day(2026, 3, 4, 15))
        ]
        #expect(rules.total(on: day(2026, 3, 4, 12), data: data) == 2.5)
    }
}
