import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("MeditationRules")
struct MeditationRulesTests {
    private let rules = MeditationRules(prefs: Prefs())

    private func rules(_ slots: Set<MeditationSlot>, minutes: Int = 5) -> MeditationRules {
        var prefs = Prefs()
        prefs.meditation.slots = slots
        prefs.meditation.sessionMinutes = minutes
        return MeditationRules(prefs: prefs)
    }

    @Test func idIsMeditation() {
        #expect(rules.id == .meditation)
    }

    @Test func launchAfterTheMorningSlotWithNoSessionIsDueAtTheMorningSlot() {
        let next = rules.nextDue(now: day(2026, 3, 4, 15), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 8))
    }

    @Test func doneInTheAfternoonIsDueAtTheEveningSlot() {
        let next = rules.nextDue(now: day(2026, 3, 4, 15, 5), lastDone: day(2026, 3, 4, 15, 5), doneToday: 5, skipToday: false)
        #expect(next == day(2026, 3, 4, 21, 30))
    }

    @Test func doneAfterTheEveningSlotIsDueTomorrowMorning() {
        let next = rules.nextDue(now: day(2026, 3, 4, 21, 40), lastDone: day(2026, 3, 4, 21, 40), doneToday: 10, skipToday: false)
        #expect(next == day(2026, 3, 5, 8))
    }

    @Test func doneExactlyAtASlotMovesToTheNextSlot() {
        let next = rules.nextDue(now: day(2026, 3, 4, 8), lastDone: day(2026, 3, 4, 8), doneToday: 5, skipToday: false)
        #expect(next == day(2026, 3, 4, 21, 30))
    }

    @Test func noSlotsIsNeverDue() {
        let next = rules([]).nextDue(now: day(2026, 3, 4, 15), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == .distantFuture)
    }

    @Test func skipTodayMovesToTheFirstSlotTomorrow() {
        let next = rules.nextDue(now: day(2026, 3, 4, 7), lastDone: nil, doneToday: 0, skipToday: true)
        #expect(next == day(2026, 3, 5, 8))
        let afternoon = rules([.afternoon, .evening]).nextDue(now: day(2026, 3, 4, 7), lastDone: nil, doneToday: 0, skipToday: true)
        #expect(afternoon == day(2026, 3, 5, 14))
    }

    @Test func lastDoneYesterdayIsIgnored() {
        let next = rules.nextDue(now: day(2026, 3, 4, 15), lastDone: day(2026, 3, 3, 22), doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 8))
    }

    @Test(arguments: [
        (Set<MeditationSlot>([.morning, .afternoon, .evening]), day(2026, 3, 4, 8, 10), day(2026, 3, 4, 14)),
        (Set<MeditationSlot>([.morning, .afternoon, .evening]), day(2026, 3, 4, 14, 10), day(2026, 3, 4, 21, 30)),
        (Set<MeditationSlot>([.afternoon]), day(2026, 3, 4, 14, 10), day(2026, 3, 5, 14)),
        (Set<MeditationSlot>([.evening]), day(2026, 3, 4, 9), day(2026, 3, 4, 21, 30))
    ])
    func nextSelectedSlotAfterLastDone(_ slots: Set<MeditationSlot>, _ done: Date, _ expected: Date) {
        #expect(rules(slots).nextDue(now: done, lastDone: done, doneToday: 5, skipToday: false) == expected)
    }

    @Test func freshDayBeforeAnySlotIsDueAtTheFirstSlot() {
        let next = rules([.afternoon]).nextDue(now: day(2026, 3, 4, 0, 1), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 14))
    }

    @Test(arguments: [day(2026, 3, 4, 3), day(2026, 3, 4, 12), day(2026, 3, 4, 23, 59)])
    func isAlwaysActive(_ date: Date) {
        #expect(rules.isActiveTime(date))
        #expect(rules.nextActiveStart(after: date) == date)
    }

    @Test(arguments: [
        (Set<MeditationSlot>([.morning, .evening]), 5, 10.0),
        (Set<MeditationSlot>([.morning, .afternoon, .evening]), 10, 30.0),
        (Set<MeditationSlot>([.afternoon]), 2, 2.0),
        (Set<MeditationSlot>(), 5, 0.0)
    ])
    func dailyGoalIsLengthTimesSlots(_ slots: Set<MeditationSlot>, _ minutes: Int, _ goal: Double) {
        #expect(rules(slots, minutes: minutes).dailyGoal == goal)
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
