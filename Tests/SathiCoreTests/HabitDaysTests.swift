import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("HabitDays")
struct HabitDaysTests {
    private let zone = FixedZone.berlin
    private var cal: Calendar { zone.calendar }

    private func keys(_ raws: String...) -> Set<DayKey> {
        Set(raws.compactMap { DayKey(raw: $0) })
    }

    private func every(but off: Weekday...) -> Set<Weekday> {
        Set(Weekday.allCases).subtracting(off)
    }

    @Test func isOnFalseOnAWeekdayThatIsOff() {
        let days = HabitDays(weekdays: every(but: .tuesday), daysOff: [])
        #expect(!days.isOn(zone.date(2026, 11, 3, 12), calendar: cal))
        #expect(!days.isOn(zone.date(2026, 11, 10, 0), calendar: cal))
        #expect(days.isOn(zone.date(2026, 11, 4, 12), calendar: cal))
        #expect(days.isOn(zone.date(2026, 11, 2, 23, 59), calendar: cal))
    }

    @Test func isOnFalseOnADateOff() {
        let days = HabitDays(weekdays: Set(Weekday.allCases), daysOff: keys("2026-11-03"))
        #expect(!days.isOn(zone.date(2026, 11, 3), calendar: cal))
        #expect(!days.isOn(zone.date(2026, 11, 3, 23, 59), calendar: cal))
        #expect(days.isOn(zone.date(2026, 11, 2, 23, 59), calendar: cal))
        #expect(days.isOn(zone.date(2026, 11, 4), calendar: cal))
        #expect(days.isOn(zone.date(2026, 11, 10, 12), calendar: cal))
    }

    @Test func emptyWeekdaysCountAsEveryDay() {
        let days = HabitDays(weekdays: [], daysOff: [])
        for offset in 0 ..< 7 {
            #expect(days.isOn(zone.adding(days: offset, to: zone.date(2026, 11, 2, 12)), calendar: cal))
        }
    }

    @Test func emptyWeekdaysStillRespectADateOff() {
        let days = HabitDays(weekdays: [], daysOff: keys("2026-11-03"))
        #expect(!days.isOn(zone.date(2026, 11, 3, 12), calendar: cal))
        #expect(days.isOn(zone.date(2026, 11, 4, 12), calendar: cal))
    }

    @Test func dateOffFollowsTheCalendarTimeZone() {
        let ny = FixedZone.newYork
        let days = HabitDays(weekdays: Set(Weekday.allCases), daysOff: keys("2026-11-03"))
        let instant = zone.date(2026, 11, 4, 2)
        #expect(days.isOn(instant, calendar: cal))
        #expect(!days.isOn(instant, calendar: ny.calendar))
    }

    @Test func nextOnDayIsTheStartOfTodayWhenTodayIsOn() {
        let days = HabitDays(weekdays: Set(Weekday.allCases), daysOff: [])
        #expect(days.nextOnDay(onOrAfter: zone.date(2026, 11, 3, 15), calendar: cal) == zone.date(2026, 11, 3))
    }

    @Test func nextOnDaySkipsADateOffAndAWeekdayOff() {
        let days = HabitDays(weekdays: every(but: .wednesday), daysOff: keys("2026-11-03"))
        #expect(days.nextOnDay(onOrAfter: zone.date(2026, 11, 3, 15), calendar: cal) == zone.date(2026, 11, 5))
    }

    @Test func onlyWeekdayAlsoOffFindsNextWeek() {
        let days = HabitDays(weekdays: [.tuesday], daysOff: keys("2026-11-03"))
        #expect(days.nextOnDay(onOrAfter: zone.date(2026, 11, 3, 10), calendar: cal) == zone.date(2026, 11, 10))
    }

    private var window: Int { Limits.daysOffMaxAhead + Limits.daysPerWeek }

    private func daysOff(from start: Date, count: Int) -> Set<DayKey> {
        Set((0 ..< count).map { DayKey(zone.adding(days: $0, to: start), calendar: cal) })
    }

    @Test func nextOnDayFindsADayAtTheEndOfTheWindow() {
        let start = zone.date(2026, 11, 3)
        let days = HabitDays(weekdays: Set(Weekday.allCases), daysOff: daysOff(from: start, count: window))
        #expect(window == 372)
        #expect(days.nextOnDay(onOrAfter: zone.date(2026, 11, 3, 10), calendar: cal) == zone.adding(days: window, to: start))
    }

    @Test func nextOnDayIsNilWhenNothingIsOnInTheWindow() {
        let start = zone.date(2026, 11, 3)
        let days = HabitDays(weekdays: Set(Weekday.allCases), daysOff: daysOff(from: start, count: window + 1))
        #expect(days.nextOnDay(onOrAfter: zone.date(2026, 11, 3, 10), calendar: cal) == nil)
    }

    @Test func aThreeWeekBreakFindsTheDayAfter() {
        let start = zone.date(2026, 11, 3)
        let days = HabitDays(weekdays: Set(Weekday.allCases), daysOff: daysOff(from: start, count: 21))
        #expect(days.nextOnDay(onOrAfter: start, calendar: cal) == zone.adding(days: 21, to: start))
    }

    @Test func nextOnDayOverADSTChangeIsLocalMidnight() {
        let ny = FixedZone.newYork
        let days = HabitDays(weekdays: Set(Weekday.allCases), daysOff: keys("2026-03-08", "2026-11-01"))
        let spring = days.nextOnDay(onOrAfter: ny.date(2026, 3, 8, 0, 30), calendar: ny.calendar)
        let fall = days.nextOnDay(onOrAfter: ny.date(2026, 11, 1, 23, 30), calendar: ny.calendar)
        #expect(spring.map(ny.wallClock) == [2026, 3, 9, 0, 0])
        #expect(fall.map(ny.wallClock) == [2026, 11, 2, 0, 0])
    }

    @Test func upcomingHidesPastDatesAndSorts() {
        let days = HabitDays(
            weekdays: Set(Weekday.allCases),
            daysOff: keys("2026-12-25", "2026-10-30", "2026-11-10", "2026-11-02", "2026-11-03")
        )
        let upcoming = days.upcoming(from: zone.date(2026, 11, 3, 15), calendar: cal)
        #expect(upcoming.map(\.raw) == ["2026-11-03", "2026-11-10", "2026-12-25"])
    }

    @Test func upcomingIsEmptyWithNoDatesOff() {
        let days = HabitDays(weekdays: [.monday], daysOff: [])
        #expect(days.upcoming(from: zone.date(2026, 11, 3, 15), calendar: cal).isEmpty)
    }
}
