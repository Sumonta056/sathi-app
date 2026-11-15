import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoDueMonth")
struct TodoDueMonthTests {
    private let z = FixedZone.berlin
    private var cal: Calendar { z.calendar }

    private func cells(_ m: DayOffMonth) -> [DayOffCell] { m.weeks.flatMap { $0 }.compactMap { $0 } }

    @Test func opensOnTheMonthOfThePickedDayWithItMarked() {
        let m = TodoDueMonth.month(selected: z.date(2026, 3, 10, 15), offset: 0, calendar: cal)
        #expect(m.firstDay == DayKey(raw: "2026-03-01"))
        #expect(cells(m).count == 31)
        #expect(cells(m).filter { $0.state == .off }.map(\.day) == [10])
    }

    @Test func everyOtherDayCanBePickedAlsoPastDays() {
        let m = TodoDueMonth.month(selected: z.date(2026, 3, 10), offset: 0, calendar: cal)
        #expect(cells(m).filter { $0.state == .pickable }.count == 30)
        #expect(m.canGoBack)
        #expect(m.canGoForward)
    }

    @Test func anOffsetMovesTheMonthAndTheMarkStaysOnItsOwnMonth() {
        let next = TodoDueMonth.month(selected: z.date(2026, 3, 10), offset: 1, calendar: cal)
        #expect(next.firstDay == DayKey(raw: "2026-04-01"))
        #expect(cells(next).allSatisfy { $0.state == .pickable })
        let back = TodoDueMonth.month(selected: z.date(2026, 1, 10), offset: -2, calendar: cal)
        #expect(back.firstDay == DayKey(raw: "2025-11-01"))
    }

    @Test func weeksUseTheSameLayoutAsTheDaysOffPicker() {
        let m = TodoDueMonth.month(selected: z.date(2026, 3, 10), offset: 0, calendar: cal)
        #expect(m.weeks.allSatisfy { $0.count == Limits.daysPerWeek })
    }
}
