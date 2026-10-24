import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ReadingRules")
struct ReadingRulesTests {
    private let rules = ReadingRules(prefs: Prefs())
    private let now = day(2026, 3, 4, 10)

    @Test func idIsReading() {
        #expect(rules.id == .reading)
    }

    @Test func nextDueToday() {
        #expect(rules.nextDue(now: now, lastDone: nil, doneToday: 0, skipToday: false) == day(2026, 3, 4, 22))
    }

    @Test func nextDueTomorrowWhenDoneOrSkipped() {
        #expect(rules.nextDue(now: now, lastDone: nil, doneToday: 15, skipToday: false) == day(2026, 3, 5, 22))
        #expect(rules.nextDue(now: now, lastDone: nil, doneToday: 0, skipToday: true) == day(2026, 3, 5, 22))
    }

    @Test func nextDueTodayWhenBelowSession() {
        #expect(rules.nextDue(now: now, lastDone: nil, doneToday: 14, skipToday: false) == day(2026, 3, 4, 22))
    }

    @Test func nextDueIgnoresLastDone() {
        let next = rules.nextDue(now: now, lastDone: day(2026, 3, 4, 9), doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 22))
    }

    @Test(arguments: [day(2026, 3, 4, 3), day(2026, 3, 4, 9, 29), day(2026, 3, 4, 18, 30), day(2026, 3, 4, 23, 59)])
    func isAlwaysActive(_ date: Date) {
        #expect(rules.isActiveTime(date))
    }

    @Test func nextActiveStartReturnsTheInput() {
        #expect(rules.nextActiveStart(after: day(2026, 3, 4, 6)) == day(2026, 3, 4, 6))
        #expect(rules.nextActiveStart(after: day(2026, 3, 4, 20)) == day(2026, 3, 4, 20))
    }

    @Test func dailyGoalIsSessionMinutes() {
        #expect(rules.dailyGoal == 15)
        var prefs = Prefs()
        prefs.reading.sessionMinutes = 25
        #expect(ReadingRules(prefs: prefs).dailyGoal == 25)
    }

    @Test func totalSumsOnlyThatDaysReads() {
        var data = Persisted()
        data.events = [
            .done(.reading, 30, at: day(2026, 3, 3, 23, 50)),
            .done(.reading, 5, at: day(2026, 3, 4, 7)),
            .done(.reading, 15, at: day(2026, 3, 4, 22)),
            .done(.reading, 15, at: day(2026, 3, 5, 22)),
            .done(.water, 3, at: day(2026, 3, 4, 12)),
            .skip(.reading, at: day(2026, 3, 4, 8))
        ]
        #expect(rules.total(on: day(2026, 3, 4, 12), data: data) == 20)
    }
}
