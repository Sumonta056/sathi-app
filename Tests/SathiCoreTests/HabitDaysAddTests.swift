import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("HabitDays adding a day off")
struct HabitDaysAddTests {
    private let zone = FixedZone.berlin
    private var cal: Calendar { zone.calendar }
    private var now: Date { zone.date(2026, 11, 3, 10) }

    private func key(_ raw: String) -> DayKey { DayKey(raw: raw)! }

    private func days(_ raws: [String]) -> HabitDays {
        HabitDays(weekdays: Set(Weekday.allCases), daysOff: Set(raws.map(key)))
    }

    @Test func addsTodayAndLaterInTheCalendarZone() {
        let d = days([]).addingDayOff(zone.date(2026, 11, 3, 0, 30), now: now, calendar: cal)
        #expect(d.daysOff == [key("2026-11-03")])
    }

    @Test func ignoresAPastDate() {
        let d = days([]).addingDayOff(zone.date(2026, 11, 2, 23, 59), now: now, calendar: cal)
        #expect(d.daysOff.isEmpty)
    }

    @Test func lastAllowedDayIsAYearAhead() {
        let base = days([])
        let last = base.addingDayOff(zone.date(2027, 11, 3, 23), now: now, calendar: cal)
        let over = base.addingDayOff(zone.date(2027, 11, 4, 0), now: now, calendar: cal)
        #expect(last.daysOff == [key("2027-11-03")])
        #expect(over.daysOff.isEmpty)
    }

    @Test func ignoresADateWhenTheFutureListIsFull() {
        let start = zone.date(2026, 11, 4)
        let full = (0 ..< Limits.daysOffMax).map { DayKey(zone.adding(days: $0, to: start), calendar: cal).raw }
        let d = days(full + ["2026-01-01"]).addingDayOff(now, now: now, calendar: cal)
        #expect(d.daysOff.count == Limits.daysOffMax + 1)
        #expect(!d.daysOff.contains(key("2026-11-03")))
    }

    @Test func lastDayOffRangeEndsAYearAhead() {
        let range = HabitDays.dayOffRange(now: now, calendar: cal)
        #expect(range.lowerBound == zone.date(2026, 11, 3))
        #expect(DayKey(range.upperBound, calendar: cal) == key("2027-11-03"))
    }
}
