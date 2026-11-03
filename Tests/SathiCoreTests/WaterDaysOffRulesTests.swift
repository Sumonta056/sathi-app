import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Water days off rules")
struct WaterDaysOffRulesTests {
    private let zone = FixedZone.berlin

    private func rules(off dates: [Date] = [], weekdays: Set<Weekday> = Set(Weekday.allCases), in zone: FixedZone = .berlin) -> WaterRules {
        var p = Prefs()
        p.water.intervalMinutes = 120
        p.water.startMinutes = 9 * 60 + 30
        p.water.endMinutes = 18 * 60 + 30
        p.water.weekdays = weekdays
        p.water.daysOff = Set(dates.map { DayKey($0, calendar: zone.calendar) })
        return WaterRules(prefs: p, calendar: zone.calendar)
    }

    private func dates(from start: Date, count: Int) -> [Date] {
        (0 ..< count).map { zone.adding(days: $0, to: start) }
    }

    @Test func waterSkipsADateOff() {
        let now = zone.date(2026, 3, 4, 18)
        let next = rules(off: [zone.date(2026, 3, 5)]).nextDue(now: now, lastDone: now, doneToday: 0, skipToday: false)
        #expect(next == zone.date(2026, 3, 6, 9, 30))
    }

    @Test func waterSkipsAWeekdayOff() {
        let now = zone.date(2026, 3, 4, 18)
        let next = rules(weekdays: Set(Weekday.allCases).subtracting([.thursday])).nextDue(now: now, lastDone: now, doneToday: 0, skipToday: false)
        #expect(next == zone.date(2026, 3, 6, 9, 30))
    }

    @Test func waterIsNotActiveOnADayOff() {
        let r = rules(off: [zone.date(2026, 3, 4)])
        #expect(!r.isActiveTime(zone.date(2026, 3, 4, 12)))
        #expect(r.isActiveTime(zone.date(2026, 3, 5, 12)))
    }

    @Test func waterIsNotActiveOnAWeekdayOff() {
        let r = rules(weekdays: Set(Weekday.allCases).subtracting([.wednesday]))
        #expect(!r.isActiveTime(zone.date(2026, 3, 4, 12)))
    }

    @Test func dueTodayOnADateOffMovesToTomorrowStart() {
        let now = zone.date(2026, 3, 4, 10)
        let next = rules(off: [zone.date(2026, 3, 4)]).nextDue(now: now, lastDone: now, doneToday: 0, skipToday: false)
        #expect(next == zone.date(2026, 3, 5, 9, 30))
    }

    @Test func dueOnTodayOffIsNeverInThePast() {
        let now = zone.date(2026, 3, 4, 10)
        let next = rules(off: [zone.date(2026, 3, 4)]).nextDue(now: now, lastDone: zone.date(2026, 3, 3, 17), doneToday: 0, skipToday: false)
        #expect(next == zone.date(2026, 3, 5, 9, 30))
        #expect(next > now)
    }

    @Test func nextActiveStartSkipsADayOff() {
        let next = rules(off: [zone.date(2026, 3, 5)]).nextActiveStart(after: zone.date(2026, 3, 4, 19))
        #expect(next == zone.date(2026, 3, 6, 9, 30))
    }

    @Test func onlyDayIsAlsoADateOff() {
        let now = zone.date(2026, 3, 4, 20)
        let next = rules(off: [zone.date(2026, 3, 11)], weekdays: [.wednesday]).nextDue(now: now, lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == zone.date(2026, 3, 18, 9, 30))
        #expect(next > now)
    }

    @Test func nothingOnInTheWindowHasNoNextReminder() {
        let now = zone.date(2026, 3, 4, 10)
        let r = rules(off: dates(from: zone.date(2026, 3, 4), count: Limits.daysOffMaxAhead + Limits.daysPerWeek + 2))
        #expect(r.nextDue(now: now, lastDone: now, doneToday: 0, skipToday: false) == .distantFuture)
        #expect(r.nextActiveStart(after: now) == .distantFuture)
    }

    @Test func aThreeWeekBreakResumesOnDay22() {
        let now = zone.date(2026, 3, 4, 20)
        let r = rules(off: dates(from: zone.date(2026, 3, 5), count: 21))
        #expect(r.nextDue(now: now, lastDone: now, doneToday: 0, skipToday: false) == zone.date(2026, 3, 26, 9, 30))
    }

    @Test func nextActiveStartAfterTheEndIsTomorrowsStart() {
        #expect(rules().nextActiveStart(after: zone.date(2026, 3, 4, 19)) == zone.date(2026, 3, 5, 9, 30))
    }

    @Test func lateCandidateOnDSTDayIsTheNextCalendarDay() {
        let ny = FixedZone.newYork
        var p = Prefs()
        p.water.intervalMinutes = 120
        p.water.startMinutes = 9 * 60 + 30
        p.water.endMinutes = 23 * 60 + 30
        let done = ny.date(2026, 3, 7, 21, 45)
        let next = WaterRules(prefs: p, calendar: ny.calendar).nextDue(now: done, lastDone: done, doneToday: 0, skipToday: false)
        #expect(ny.wallClock(next) == [2026, 3, 8, 9, 30])
    }

    @Test func offDateOnDSTDay() {
        let ny = FixedZone.newYork
        let done = ny.date(2026, 3, 7, 18)
        let next = rules(off: [ny.date(2026, 3, 8)], in: ny).nextDue(now: done, lastDone: done, doneToday: 0, skipToday: false)
        #expect(ny.wallClock(next) == [2026, 3, 9, 9, 30])
    }
}
