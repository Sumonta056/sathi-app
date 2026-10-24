import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("StreakCalculator current")
struct StreakCalculatorTests {
    private let zone = FixedZone.berlin
    private var today: Date { zone.date(2026, 3, 4, 12) }
    private var waterGoal: Double { HabitID.water.rules(Prefs(), calendar: zone.calendar).dailyGoal }
    private var readingGoal: Double { HabitID.reading.rules(Prefs(), calendar: zone.calendar).dailyGoal }

    private func current(_ id: HabitID, goal: Double, _ events: [HistoryEvent], reset: Date? = nil) -> Int {
        let store = InMemoryHistoryStore(events: events)
        return StreakCalculator(calendar: zone.calendar)
            .current(id, goal: goal, reset: reset, now: today) { store.events(from: $0.start, to: $0.end) }
    }

    private func goalDays(_ count: Int, endingAt end: Date) -> [HistoryEvent] {
        zone.doneDays(.water, 8, count: count, endingAt: end)
    }

    private var yesterday: Date { zone.adding(days: -1, to: today) }

    @Test func waterStreakCountsConsecutiveGoalDays() {
        #expect(current(.water, goal: waterGoal, goalDays(3, endingAt: today)) == 3)
    }

    @Test func streakSurvivesUnfinishedToday() {
        #expect(current(.water, goal: waterGoal, goalDays(2, endingAt: yesterday)) == 2)
    }

    @Test func gapEndsTheStreak() {
        let events = goalDays(1, endingAt: today) + goalDays(3, endingAt: zone.adding(days: -2, to: today))
        #expect(current(.water, goal: waterGoal, events) == 1)
    }

    @Test func streakResetKeepsOnlyDaysAfterReset() {
        #expect(current(.water, goal: waterGoal, goalDays(3, endingAt: today), reset: today.addingTimeInterval(-1)) == 1)
    }

    @Test func eventAtTheResetMomentDoesNotCount() {
        #expect(current(.water, goal: waterGoal, goalDays(1, endingAt: today), reset: today) == 0)
    }

    @Test func readingStreakUsesSessionLength() {
        #expect(current(.reading, goal: readingGoal, [.done(.reading, 10, at: today)]) == 0)
        #expect(current(.reading, goal: readingGoal, [.done(.reading, 10, at: today), .done(.reading, 5, at: today)]) == 1)
    }

    @Test func snoozesAndSkipsNeverCountTowardTheStreak() {
        let events: [HistoryEvent] = [.skip(.reading, at: today), .snooze(.reading, at: today), .done(.reading, 10, at: today)]
        #expect(current(.reading, goal: readingGoal, events) == 0)
    }

    @Test func aGoalOfZeroNeverCountsAsMet() {
        var prefs = Prefs()
        prefs.meditation.slots = []
        let goal = HabitID.meditation.rules(prefs, calendar: zone.calendar).dailyGoal
        #expect(current(.meditation, goal: goal, [.done(.meditation, 5, at: zone.date(2026, 3, 3, 8, 5))]) == 0)
    }

    @Test func goalZeroGivesZeroEvenWithDoneDays() {
        #expect(current(.water, goal: 0, goalDays(5, endingAt: today)) == 0)
    }

    @Test(arguments: [(true, true, 4), (false, true, 3), (true, false, 1), (false, false, 0)])
    func todayAddsOneOnlyWhenMet(_ todayMet: Bool, _ yesterdayMet: Bool, _ expected: Int) {
        var events = goalDays(2, endingAt: zone.adding(days: -2, to: today))
        if yesterdayMet { events += goalDays(1, endingAt: yesterday) }
        if todayMet { events += goalDays(1, endingAt: today) }
        #expect(current(.water, goal: waterGoal, events) == expected)
    }

    @Test func otherHabitsNeverCount() {
        let events = zone.doneDays(.reading, 30, count: 3, endingAt: today)
        #expect(current(.water, goal: waterGoal, events) == 0)
    }

    @Test func doneAmountsOfADaySumBeforeTheGoalIsChecked() {
        let events = (0 ..< 8).map { HistoryEvent.done(.water, 1, at: zone.date(2026, 3, 3, 9 + $0)) }
        #expect(current(.water, goal: waterGoal, events) == 1)
    }

    @Test func doneBeforeTheResetOnTheSameDayDoesNotCount() {
        let events: [HistoryEvent] = [.done(.water, 4, at: zone.date(2026, 3, 4, 9)), .done(.water, 4, at: zone.date(2026, 3, 4, 11))]
        #expect(current(.water, goal: waterGoal, events, reset: zone.date(2026, 3, 4, 10)) == 0)
        #expect(current(.water, goal: waterGoal, events) == 1)
    }
}
