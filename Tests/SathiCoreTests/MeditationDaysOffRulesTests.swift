import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Meditation days off rules")
struct MeditationDaysOffRulesTests {
    private let zone = FixedZone.berlin

    private func rules(off dates: [Date] = [], weekdays: Set<Weekday> = Set(Weekday.allCases)) -> MeditationRules {
        var p = Prefs()
        p.meditation.enabled = true
        p.meditation.intervalMinutes = 60
        p.meditation.startMinutes = 9 * 60
        p.meditation.endMinutes = 21 * 60
        p.meditation.dailyGoalMinutes = 10
        p.meditation.weekdays = weekdays
        p.meditation.daysOff = Set(dates.map { DayKey($0, calendar: zone.calendar) })
        return MeditationRules(prefs: p, calendar: zone.calendar)
    }

    @Test func meditationSkipsADateOffAndKeepsTheGoalRule() {
        let now = zone.date(2026, 3, 4, 12)
        let next = rules(off: [zone.date(2026, 3, 5)]).nextDue(now: now, lastDone: now, doneToday: 10, skipToday: false)
        #expect(next == zone.date(2026, 3, 6, 9))
    }

    @Test func goalMetWithTomorrowOnIsTomorrowsStart() {
        let now = zone.date(2026, 3, 4, 12)
        let next = rules().nextDue(now: now, lastDone: now, doneToday: 10, skipToday: false)
        #expect(next == zone.date(2026, 3, 5, 9))
    }

    @Test func afterTheEndSkipsADateOff() {
        let done = zone.date(2026, 3, 4, 20, 30)
        let next = rules(off: [zone.date(2026, 3, 5)]).nextDue(now: done, lastDone: done, doneToday: 2, skipToday: false)
        #expect(next == zone.date(2026, 3, 6, 9))
    }

    @Test func skipsAWeekdayOff() {
        let done = zone.date(2026, 3, 4, 20, 30)
        let next = rules(weekdays: Set(Weekday.allCases).subtracting([.thursday])).nextDue(now: done, lastDone: done, doneToday: 2, skipToday: false)
        #expect(next == zone.date(2026, 3, 6, 9))
    }

    @Test func dueTodayOnADateOffMovesToTomorrowStart() {
        let now = zone.date(2026, 3, 4, 10)
        let next = rules(off: [zone.date(2026, 3, 4)]).nextDue(now: now, lastDone: now, doneToday: 2, skipToday: false)
        #expect(next == zone.date(2026, 3, 5, 9))
        #expect(next > now)
    }

    @Test func isNotActiveOnADayOff() {
        #expect(!rules(off: [zone.date(2026, 3, 4)]).isActiveTime(zone.date(2026, 3, 4, 12)))
        #expect(!rules(weekdays: Set(Weekday.allCases).subtracting([.wednesday])).isActiveTime(zone.date(2026, 3, 4, 12)))
        #expect(rules(off: [zone.date(2026, 3, 4)]).isActiveTime(zone.date(2026, 3, 5, 12)))
    }

    @Test func nextActiveStartSkipsADayOff() {
        let next = rules(off: [zone.date(2026, 3, 5)]).nextActiveStart(after: zone.date(2026, 3, 4, 22))
        #expect(next == zone.date(2026, 3, 6, 9))
    }

    @Test func aThreeWeekBreakResumesOnDay22() {
        let now = zone.date(2026, 3, 4, 12)
        let off = (0 ..< 21).map { zone.adding(days: $0, to: zone.date(2026, 3, 5)) }
        #expect(rules(off: off).nextDue(now: now, lastDone: now, doneToday: 10, skipToday: false) == zone.date(2026, 3, 26, 9))
    }

    @Test func nothingOnInTheWindowHasNoNextReminder() {
        let now = zone.date(2026, 3, 4, 10)
        let off = (0 ..< Limits.daysOffMaxAhead + Limits.daysPerWeek + 2).map { zone.adding(days: $0, to: zone.date(2026, 3, 4)) }
        #expect(rules(off: off).nextDue(now: now, lastDone: now, doneToday: 0, skipToday: false) == .distantFuture)
        #expect(rules(off: off).nextDue(now: now, lastDone: now, doneToday: 10, skipToday: false) == .distantFuture)
    }
}
