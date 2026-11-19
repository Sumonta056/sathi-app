import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar week days")
struct EngineCalendarWeekDaysTests {
    private let wedLate = day(2026, 11, 18, 22, 27)

    private func raws(_ days: [DayKey]) -> [String] { days.map(\.raw) }

    private func nov(_ days: ClosedRange<Int>) -> [String] {
        days.map { String(format: "2026-11-%02d", $0) }
    }

    @Test func todayWeekIsTheSaturdayWeekByDefault() {
        let h = EngineHarness(at: wedLate)
        let range = h.engine.calendarPageToday(.week)
        #expect(raws(range.days) == nov(14 ... 20))
        #expect(range.weekDays == 7)
        #expect(h.engine.data.prefs.calendarPage.weekDays == 7)
    }

    @Test(arguments: [3, 4, 5, 7])
    func settingTheDayCountSavesIt(_ count: Int) {
        let h = EngineHarness(at: wedLate)
        h.engine.setCalendarWeekDays(count)
        #expect(h.store.prefs.calendarPage.weekDays == count)
        #expect(h.engine.data.prefs.calendarPage.weekDays == count)
    }

    @Test(arguments: [0, 1, 2, 6, 8, 14, -3])
    func anUnknownDayCountIsIgnored(_ count: Int) {
        let h = EngineHarness(at: wedLate)
        h.engine.setCalendarWeekDays(4)
        h.engine.setCalendarWeekDays(count)
        #expect(h.store.prefs.calendarPage.weekDays == 4)
        #expect(raws(h.engine.calendarPageToday(.week).days) == nov(16 ... 19))
    }

    @Test(arguments: [(3, 17, 19), (4, 16, 19), (5, 16, 20), (7, 14, 20)])
    func todayAfterSettingTheDayCountPutsTodayInTheMiddle(_ count: Int, _ first: Int, _ last: Int) {
        let h = EngineHarness(at: wedLate)
        h.engine.setCalendarWeekDays(count)
        let range = h.engine.calendarPageToday(.week)
        #expect(raws(range.days) == nov(first ... last))
        #expect(range.weekDays == count)
        #expect(range.holds(wedLate))
    }

    @Test(arguments: [(3, 17, 19), (4, 16, 19), (5, 16, 20), (7, 14, 20)])
    func halfPastOneOnThursdayKeepsWednesdayAsToday(_ count: Int, _ first: Int, _ last: Int) {
        let h = EngineHarness(at: day(2026, 11, 19, 1, 30))
        h.engine.setCalendarWeekDays(count)
        #expect(raws(h.engine.calendarPageToday(.week).days) == nov(first ... last))
    }

    @Test(arguments: [(3, 16, 18), (4, 15, 18), (5, 15, 19)])
    func aSavedDayCountIsUsedAtStart(_ count: Int, _ first: Int, _ last: Int) {
        let h = EngineHarness(at: day(2026, 11, 17, 12)) { $0.prefs.calendarPage.weekDays = count }
        let range = h.engine.calendarPageToday(.week)
        #expect(raws(range.days) == nov(first ... last))
        #expect(range.days.count == count)
    }

    @Test func todayFollowsTheClock() {
        let h = EngineHarness(at: wedLate)
        h.engine.setCalendarWeekDays(3)
        h.advance(minutes: 24 * 60)
        #expect(raws(h.engine.calendarPageToday(.week).days) == nov(18 ... 20))
    }

    @Test func todayAfterBrowsingAwayGoesBackToTheDefaultRange() {
        let h = EngineHarness(at: wedLate)
        h.engine.setCalendarWeekDays(5)
        let browsed = h.engine.calendarPageToday(.week).next.next
        #expect(raws(browsed.days) == ["2026-11-26", "2026-11-27", "2026-11-28", "2026-11-29", "2026-11-30"])
        #expect(raws(h.engine.calendarPageToday(.week).days) == nov(16 ... 20))
    }

    @Test(arguments: [3, 4, 5])
    func dayAndMonthIgnoreTheDayCount(_ count: Int) {
        let h = EngineHarness(at: wedLate)
        h.engine.setCalendarWeekDays(count)
        #expect(raws(h.engine.calendarPageToday(.day).days) == ["2026-11-18"])
        let month = h.engine.calendarPageToday(.month)
        #expect(month.days.count == 30)
        #expect(month.days.first?.raw == "2026-11-01")
    }

    @Test(arguments: [3, 4, 5])
    func switchingFromDayToWeekUsesTheSavedCount(_ count: Int) {
        let h = EngineHarness(at: wedLate)
        h.engine.setCalendarWeekDays(count)
        let week = h.engine.calendarPageToday(.day).changed(to: .week, now: wedLate)
        #expect(week.days.count == count)
        #expect(week == h.engine.calendarPageToday(.week))
    }

    @Test func settingTheDayCountKeepsTheOtherPagePrefs() {
        let h = EngineHarness(at: wedLate) {
            $0.prefs.calendarPage.isOn = true
            $0.prefs.calendarPage.rowMinutes = 30
            $0.prefs.calendarPage.sidePanelShownWeek = true
        }
        h.engine.setCalendarWeekDays(3)
        let saved = h.store.prefs.calendarPage
        #expect(saved.weekDays == 3)
        #expect(saved.isOn == true)
        #expect(saved.rowMinutes == 30)
        #expect(saved.sidePanelShownWeek == true)
    }
}
