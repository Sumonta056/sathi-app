import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Day off month")
struct DayOffMonthTests {
    private let zone = FixedZone("Europe/Berlin")
    private var now: Date { zone.date(2026, 11, 7, 10) }

    private func days(_ off: [String] = []) -> HabitDays {
        HabitDays(weekdays: [], daysOff: Set(off.map { DayKey(raw: $0)! }))
    }

    private func month(_ d: HabitDays, _ offset: Int) -> DayOffMonth {
        d.month(offset: offset, now: now, calendar: zone.calendar)
    }

    private func cell(_ m: DayOffMonth, _ raw: String) -> DayOffCell? {
        m.weeks.flatMap { $0 }.compactMap { $0 }.first { $0.key.raw == raw }
    }

    @Test
    func novemberStartsOnASundayWithSixLeadingBlanks() {
        let m = month(days(), 0)
        let flat = m.weeks.flatMap { $0 }
        #expect(flat.compactMap { $0 }.count == 30)
        #expect(flat.prefix(6).allSatisfy { $0 == nil })
        #expect(flat[6]?.key.raw == "2026-11-01")
        #expect(m.firstDay.raw == "2026-11-01")
        #expect(m.canGoBack == false)
        #expect(m.canGoForward)
    }

    @Test
    func daysBeforeTodayAreUnavailableAndTodayIsPickable() {
        let m = month(days(), 0)
        for d in 1 ... 6 {
            #expect(cell(m, String(format: "2026-11-%02d", d))?.state == .unavailable)
        }
        #expect(cell(m, "2026-11-07")?.state == .pickable)
        #expect(cell(m, "2026-11-30")?.state == .pickable)
    }

    @Test
    func aDayOffIsMarkedOff() {
        let m = month(days(["2026-11-12"]), 0)
        #expect(cell(m, "2026-11-12")?.state == .off)
        #expect(cell(m, "2026-11-13")?.state == .pickable)
    }

    @Test
    func theLastMonthStopsAfterTheYearAheadLimit() {
        let m = month(days(), 12)
        #expect(m.firstDay.raw == "2027-11-01")
        #expect(m.canGoBack)
        #expect(m.canGoForward == false)
        #expect(cell(m, "2027-11-07")?.state == .pickable)
        #expect(cell(m, "2027-11-08")?.state == .unavailable)
        #expect(cell(m, "2027-11-30")?.state == .unavailable)
    }

    @Test
    func aFullListLeavesNothingPickable() {
        let off = (0 ..< Limits.daysOffMax).map { n in
            DayKey(zone.adding(days: n, to: now), calendar: zone.calendar).raw
        }
        let m = month(days(off), 0)
        let states = m.weeks.flatMap { $0 }.compactMap { $0?.state }
        #expect(!states.contains(.pickable))
        #expect(states.contains(.off))
    }

    @Test
    func aDaylightSavingMonthHasEveryDayOnce() {
        let m = month(days(), 4)
        let keys = m.weeks.flatMap { $0 }.compactMap { $0?.key }
        #expect(m.firstDay.raw == "2027-03-01")
        #expect(keys.count == 31)
        #expect(Set(keys).count == 31)
    }

    @Test
    func everyWeekHasSevenSlots() {
        for offset in 0 ... 12 {
            #expect(month(days(), offset).weeks.allSatisfy { $0.count == Limits.daysPerWeek })
        }
    }
}
