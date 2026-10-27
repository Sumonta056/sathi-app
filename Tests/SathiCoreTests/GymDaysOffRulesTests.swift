import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Gym days off rules")
struct GymDaysOffRulesTests {
    private let zone = FixedZone.berlin

    private func rules(off dates: [Date] = [], weekdays: Set<Weekday> = Set(Weekday.allCases)) -> GymRules {
        var p = Prefs()
        p.gym.enabled = true
        p.gym.intervalMinutes = 60
        p.gym.startMinutes = 9 * 60
        p.gym.endMinutes = 17 * 60
        p.gym.weekdays = weekdays
        p.gym.daysOff = Set(dates.map { DayKey($0, calendar: zone.calendar) })
        return GymRules(prefs: p, calendar: zone.calendar)
    }

    @Test func gymSkipsADateOffToStartPlusInterval() {
        let done = zone.date(2026, 3, 4, 16, 30)
        let next = rules(off: [zone.date(2026, 3, 5)]).nextDue(now: done, lastDone: done, doneToday: 1, skipToday: false)
        #expect(next == zone.date(2026, 3, 6, 10))
    }

    @Test func dueTodayOnADateOffMovesToTomorrow() {
        let now = zone.date(2026, 3, 4, 11)
        let next = rules(off: [zone.date(2026, 3, 4)]).nextDue(now: now, lastDone: now, doneToday: 1, skipToday: false)
        #expect(next == zone.date(2026, 3, 5, 10))
        #expect(next > now)
    }

    @Test func skipTodayWithTomorrowOffWaitsForTheNextOnDay() {
        let next = rules(off: [zone.date(2026, 3, 5)]).nextDue(now: zone.date(2026, 3, 4, 11), lastDone: nil, doneToday: 0, skipToday: true)
        #expect(next == zone.date(2026, 3, 6, 10))
    }

    @Test func dateOffAndWeekdayOffAreBothSkipped() {
        let done = zone.date(2026, 3, 4, 16, 30)
        let r = rules(off: [zone.date(2026, 3, 5)], weekdays: Set(Weekday.allCases).subtracting([.friday]))
        #expect(r.nextDue(now: done, lastDone: done, doneToday: 1, skipToday: false) == zone.date(2026, 3, 7, 10))
    }

    @Test func isNotActiveOnADateOff() {
        let r = rules(off: [zone.date(2026, 3, 4)])
        #expect(!r.isActiveTime(zone.date(2026, 3, 4, 12)))
        #expect(r.isActiveTime(zone.date(2026, 3, 5, 12)))
    }

    @Test func nextActiveStartSkipsADateOff() {
        let next = rules(off: [zone.date(2026, 3, 5)]).nextActiveStart(after: zone.date(2026, 3, 4, 18))
        #expect(next == zone.date(2026, 3, 6, 9))
    }

    @Test func aThreeWeekBreakResumesOnDay22() {
        let done = zone.date(2026, 3, 4, 16, 30)
        let off = (0 ..< 21).map { zone.adding(days: $0, to: zone.date(2026, 3, 5)) }
        #expect(rules(off: off).nextDue(now: done, lastDone: done, doneToday: 1, skipToday: false) == zone.date(2026, 3, 26, 10))
    }

    @Test func nothingOnInTheWindowHasNoNextReminder() {
        let now = zone.date(2026, 3, 4, 11)
        let off = (0 ..< Limits.daysOffMaxAhead + Limits.daysPerWeek + 2).map { zone.adding(days: $0, to: zone.date(2026, 3, 4)) }
        let r = rules(off: off)
        #expect(r.nextDue(now: now, lastDone: now, doneToday: 1, skipToday: false) == .distantFuture)
        #expect(r.nextActiveStart(after: now) == .distantFuture)
    }
}
