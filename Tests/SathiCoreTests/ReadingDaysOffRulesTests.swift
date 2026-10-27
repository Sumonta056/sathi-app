import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Reading days off rules")
struct ReadingDaysOffRulesTests {
    private let zone = FixedZone.berlin

    private func rules(off dates: [Date] = [], weekdays: Set<Weekday> = Set(Weekday.allCases)) -> ReadingRules {
        var p = Prefs()
        p.reading.timeMinutes = 22 * 60
        p.reading.sessionMinutes = 15
        p.reading.weekdays = weekdays
        p.reading.daysOff = Set(dates.map { DayKey($0, calendar: zone.calendar) })
        return ReadingRules(prefs: p, calendar: zone.calendar)
    }

    @Test func readingSkipsADateOffAtItsSetTime() {
        let next = rules(off: [zone.date(2026, 3, 4)]).nextDue(now: zone.date(2026, 3, 4, 8), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == zone.date(2026, 3, 5, 22))
    }

    @Test func dateOffAndWeekdayOffAreBothSkipped() {
        let r = rules(off: [zone.date(2026, 3, 4)], weekdays: Set(Weekday.allCases).subtracting([.thursday]))
        let next = r.nextDue(now: zone.date(2026, 3, 4, 8), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == zone.date(2026, 3, 6, 22))
    }

    @Test func goalMetWithTomorrowOffWaitsForTheNextOnDay() {
        let next = rules(off: [zone.date(2026, 3, 5)]).nextDue(now: zone.date(2026, 3, 4, 23), lastDone: nil, doneToday: 15, skipToday: false)
        #expect(next == zone.date(2026, 3, 6, 22))
    }

    @Test func nextSlotSkipsADateOff() {
        let next = rules(off: [zone.date(2026, 3, 4)]).nextSlot(after: zone.date(2026, 3, 4, 8))
        #expect(next == zone.date(2026, 3, 5, 22))
    }

    @Test func isNotActiveOnADayOff() {
        #expect(!rules(off: [zone.date(2026, 3, 4)]).isActiveTime(zone.date(2026, 3, 4, 12)))
        #expect(!rules(weekdays: Set(Weekday.allCases).subtracting([.wednesday])).isActiveTime(zone.date(2026, 3, 4, 12)))
        #expect(rules(off: [zone.date(2026, 3, 4)]).isActiveTime(zone.date(2026, 3, 5, 12)))
    }

    @Test func nextActiveStartSkipsADayOff() {
        let next = rules(off: [zone.date(2026, 3, 4)]).nextActiveStart(after: zone.date(2026, 3, 4, 12))
        #expect(next == zone.date(2026, 3, 5, 22))
    }

    @Test func snoozeEndingOnTheWeekendWaitsForMondaysSetTime() {
        let r = rules(weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday])
        let snoozeEnd = zone.date(2026, 3, 7, 0, 5)
        #expect(!r.isActiveTime(snoozeEnd))
        #expect(r.nextActiveStart(after: snoozeEnd) == zone.date(2026, 3, 9, 22))
    }

    @Test func aThreeWeekBreakResumesOnDay22() {
        let off = (0 ..< 21).map { zone.adding(days: $0, to: zone.date(2026, 3, 5)) }
        let next = rules(off: off).nextDue(now: zone.date(2026, 3, 4, 23), lastDone: nil, doneToday: 15, skipToday: false)
        #expect(next == zone.date(2026, 3, 26, 22))
    }

    @Test func nothingOnInTheWindowHasNoNextReminder() {
        let off = (0 ..< Limits.daysOffMaxAhead + Limits.daysPerWeek + 2).map { zone.adding(days: $0, to: zone.date(2026, 3, 4)) }
        let r = rules(off: off)
        let now = zone.date(2026, 3, 4, 8)
        #expect(r.nextDue(now: now, lastDone: nil, doneToday: 0, skipToday: false) == .distantFuture)
        #expect(r.nextSlot(after: now) == .distantFuture)
    }
}
