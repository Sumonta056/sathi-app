import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("MeditationRules")
struct MeditationRulesTests {
    private let rules = MeditationRules(prefs: Prefs())

    private func rules(goal: Int = 10, every interval: Int = 60, from start: Int = 9 * 60, to end: Int = 21 * 60) -> MeditationRules {
        var prefs = Prefs()
        prefs.meditation.dailyGoalMinutes = goal
        prefs.meditation.intervalMinutes = interval
        prefs.meditation.startMinutes = start
        prefs.meditation.endMinutes = end
        return MeditationRules(prefs: prefs)
    }

    @Test func idIsMeditation() {
        #expect(rules.id == .meditation)
    }

    @Test func launchInsideHoursWithNoSessionIsDueOneIntervalLater() {
        let next = rules.nextDue(now: day(2026, 3, 4, 15), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 16))
    }

    @Test func doneInTheAfternoonIsDueOneIntervalAfterTheDoneTime() {
        let next = rules.nextDue(now: day(2026, 3, 4, 15, 5), lastDone: day(2026, 3, 4, 15, 5), doneToday: 2, skipToday: false)
        #expect(next == day(2026, 3, 4, 16, 5))
    }

    @Test func doneAfterTheEndIsDueTomorrowAtTheStart() {
        let next = rules.nextDue(now: day(2026, 3, 4, 21, 40), lastDone: day(2026, 3, 4, 21, 40), doneToday: 2, skipToday: false)
        #expect(next == day(2026, 3, 5, 9))
    }

    @Test func nextDueAtTheEndMovesToTomorrowsStart() {
        let next = rules.nextDue(now: day(2026, 3, 4, 20), lastDone: day(2026, 3, 4, 20), doneToday: 2, skipToday: false)
        #expect(next == day(2026, 3, 5, 9))
    }

    @Test func skipTodayMovesToTomorrowsStart() {
        let next = rules.nextDue(now: day(2026, 3, 4, 7), lastDone: nil, doneToday: 0, skipToday: true)
        #expect(next == day(2026, 3, 5, 9))
        let later = rules(from: 14 * 60).nextDue(now: day(2026, 3, 4, 7), lastDone: nil, doneToday: 0, skipToday: true)
        #expect(later == day(2026, 3, 5, 14))
    }

    @Test func lastDoneYesterdayAfterTheEndIsDueAtTodaysStart() {
        let next = rules.nextDue(now: day(2026, 3, 4, 15), lastDone: day(2026, 3, 3, 22), doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 9))
    }

    @Test(arguments: [
        (60, day(2026, 3, 4, 10, 10), day(2026, 3, 4, 11, 10)),
        (90, day(2026, 3, 4, 10), day(2026, 3, 4, 11, 30)),
        (120, day(2026, 3, 4, 8), day(2026, 3, 4, 10)),
        (30, day(2026, 3, 4, 20, 40), day(2026, 3, 5, 9))
    ])
    func nextIntervalAfterLastDone(_ interval: Int, _ done: Date, _ expected: Date) {
        #expect(rules(every: interval).nextDue(now: done, lastDone: done, doneToday: 2, skipToday: false) == expected)
    }

    @Test func freshDayBeforeTheStartIsDueAtTheStart() {
        let next = rules(from: 14 * 60).nextDue(now: day(2026, 3, 4, 0, 1), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 14))
    }

    @Test(arguments: [
        (day(2026, 3, 4, 7, 29), false),
        (day(2026, 3, 4, 7, 30), true),
        (day(2026, 3, 4, 21, 59), true),
        (day(2026, 3, 4, 22), false)
    ])
    func isActiveOnlyBetweenStartAndEnd(_ date: Date, _ active: Bool) {
        #expect(rules(from: 7 * 60 + 30, to: 22 * 60).isActiveTime(date) == active)
    }

    @Test func nextActiveStartIsTodayBeforeTheStartAndTomorrowAfterIt() {
        let r = rules(from: 7 * 60 + 30, to: 22 * 60)
        #expect(r.nextActiveStart(after: day(2026, 3, 4, 6)) == day(2026, 3, 4, 7, 30))
        #expect(r.nextActiveStart(after: day(2026, 3, 4, 12)) == day(2026, 3, 5, 7, 30))
    }

    @Test func hasNoSlots() {
        #expect(rules.nextSlot(after: day(2026, 3, 4, 12)) == nil)
    }

    @Test(arguments: [5, 10, 20])
    func dailyGoalIsTheGoalMinutesNotTheSessionLength(_ goal: Int) {
        var prefs = Prefs()
        prefs.meditation.dailyGoalMinutes = goal
        prefs.meditation.sessionMinutes = 1
        #expect(MeditationRules(prefs: prefs).dailyGoal == Double(goal))
    }

    @Test func totalCountsOnlyThatDaysDoneMeditationMinutes() {
        var data = Persisted()
        data.events = [
            .done(.meditation, 10, at: day(2026, 3, 3, 23, 50)),
            .done(.meditation, 5, at: day(2026, 3, 4, 8, 5)),
            .done(.meditation, 2, at: day(2026, 3, 4, 21, 35)),
            .done(.meditation, 5, at: day(2026, 3, 5, 8)),
            .done(.reading, 15, at: day(2026, 3, 4, 22)),
            .done(.water, 3, at: day(2026, 3, 4, 12)),
            .snooze(.meditation, at: day(2026, 3, 4, 14)),
            .skip(.meditation, at: day(2026, 3, 4, 15))
        ]
        #expect(rules.total(on: day(2026, 3, 4, 12), data: data) == 7)
    }

    @Test func lastDoneIsTheLastDoneMeditationEvent() {
        var data = Persisted()
        #expect(data.lastDone(.meditation) == nil)
        data.events = [
            .done(.meditation, 5, at: day(2026, 3, 3, 21, 35)),
            .done(.meditation, 5, at: day(2026, 3, 4, 8, 5)),
            .snooze(.meditation, at: day(2026, 3, 4, 14)),
            .done(.reading, 15, at: day(2026, 3, 4, 22))
        ]
        #expect(data.lastDone(.meditation) == day(2026, 3, 4, 8, 5))
    }
}
