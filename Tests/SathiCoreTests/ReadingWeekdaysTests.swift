import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Reading weekdays")
struct ReadingWeekdaysTests {
    private let zone = FixedZone.berlin

    private func rules(_ days: Set<Weekday>) -> ReadingRules {
        var p = Prefs()
        p.reading.timeMinutes = 22 * 60
        p.reading.weekdays = days
        return ReadingRules(prefs: p, calendar: zone.calendar)
    }

    private var weekdaysOnly: Set<Weekday> { [.monday, .tuesday, .wednesday, .thursday, .friday] }

    @Test func goalMetOnFridayWaitsForMonday() {
        let next = rules(weekdaysOnly).nextDue(now: zone.date(2026, 3, 6, 23), lastDone: nil, doneToday: 15, skipToday: false)
        #expect(next == zone.date(2026, 3, 9, 22))
    }

    @Test func skipOnFridayWaitsForMonday() {
        let next = rules(weekdaysOnly).nextDue(now: zone.date(2026, 3, 6, 9), lastDone: nil, doneToday: 0, skipToday: true)
        #expect(next == zone.date(2026, 3, 9, 22))
    }

    @Test func aDayThatIsOffWaitsForTheNextSelectedDay() {
        let next = rules(weekdaysOnly).nextDue(now: zone.date(2026, 3, 7, 8), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == zone.date(2026, 3, 9, 22))
    }

    @Test func selectedDayBeforeTheSetTimeIsDueToday() {
        let next = rules(weekdaysOnly).nextDue(now: zone.date(2026, 3, 4, 10), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == zone.date(2026, 3, 4, 22))
    }

    @Test func selectedDayAfterTheSetTimeWithNothingDoneIsTodaysSetTime() {
        let next = rules(weekdaysOnly).nextDue(now: zone.date(2026, 3, 4, 23), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == zone.date(2026, 3, 4, 22))
    }

    @Test func onlyOneDaySelectedAndDoneWaitsAWholeWeek() {
        let next = rules([.wednesday]).nextDue(now: zone.date(2026, 3, 4, 23), lastDone: nil, doneToday: 15, skipToday: false)
        #expect(next == zone.date(2026, 3, 11, 22))
    }

    @Test func stepsAcrossTheSpringDSTChangeAtTheSetTime() {
        let next = rules([.monday]).nextDue(now: zone.date(2026, 3, 28, 8), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(zone.wallClock(next) == [2026, 3, 30, 22, 0])
    }

    @Test func stepsAcrossTheAutumnDSTChangeAtTheSetTime() {
        let next = rules([.monday]).nextDue(now: zone.date(2026, 10, 24, 23), lastDone: nil, doneToday: 15, skipToday: false)
        #expect(zone.wallClock(next) == [2026, 10, 26, 22, 0])
        #expect(next == zone.date(2026, 10, 26, 22))
    }

    @Test func nextSlotSkipsDaysThatAreOff() {
        let r = rules(weekdaysOnly)
        #expect(r.nextSlot(after: zone.date(2026, 3, 6, 23)) == zone.date(2026, 3, 9, 22))
        #expect(r.nextSlot(after: zone.date(2026, 3, 7, 8)) == zone.date(2026, 3, 9, 22))
    }

    @Test func nextSlotOnASelectedDayBeforeTheSetTimeIsToday() {
        #expect(rules(weekdaysOnly).nextSlot(after: zone.date(2026, 3, 6, 21)) == zone.date(2026, 3, 6, 22))
    }

    @Test func nextSlotIsStrictlyAfterTheDate() {
        #expect(rules(weekdaysOnly).nextSlot(after: zone.date(2026, 3, 6, 22)) == zone.date(2026, 3, 9, 22))
    }

    @Test func emptyWeekdaysActsAsEveryDay() {
        let r = rules([])
        #expect(r.nextDue(now: zone.date(2026, 3, 7, 8), lastDone: nil, doneToday: 0, skipToday: false) == zone.date(2026, 3, 7, 22))
        #expect(r.nextDue(now: zone.date(2026, 3, 6, 23), lastDone: nil, doneToday: 15, skipToday: false) == zone.date(2026, 3, 7, 22))
        #expect(r.nextSlot(after: zone.date(2026, 3, 6, 23)) == zone.date(2026, 3, 7, 22))
    }
}
