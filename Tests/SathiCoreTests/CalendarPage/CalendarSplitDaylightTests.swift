import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar split layout: daylight saving")
struct CalendarSplitDaylightTests {
    private let zone = FixedZone.newYork
    private let fallBack = (month: 10, day: 31)
    private let springForward = (month: 3, day: 7)

    private func activity(_ id: String, _ from: Date, _ to: Date) -> CalendarBlock {
        let a = Activity(kind: .work, text: id, category: "Focus", start: from, end: to)
        return CalendarBlock(
            id: id, title: id, interval: DateInterval(start: from, end: to), style: .activity(category: "Focus"),
            source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        )
    }

    private func page(_ month: Int, _ date: Int) -> DayKey {
        DayKey(zone.date(2026, month, date, 12), calendar: zone.calendar)
    }

    private func layout(_ blocks: [CalendarBlock], on key: DayKey) -> CalendarGridLayout {
        CalendarSplitLayout.layout(blocks, days: [key], calendar: zone.calendar, rowMinutes: 60, metrics: Split.day)
    }

    private func labelRow(_ hour: Int) -> Int {
        (hour - Limits.calendarPageDayStartHour + Limits.calendarGridHours) % Limits.calendarGridHours
    }

    @Test func fallBackDayEndBlockSitsInItsLabelRow() {
        let key = page(fallBack.month, fallBack.day)
        let grid = layout([activity("late", zone.date(2026, 11, 1, 5, 20), zone.date(2026, 11, 1, 5, 50))], on: key)
        let late = grid.days[key]?.first { $0.id == "late" }
        let row = grid.rowAt(labelRow(5))
        #expect(late?.top == row.map { $0.top + 20 })
        #expect(late.map { $0.top < $0.bottom } == true)
        #expect(late.map { $0.bottom - $0.top < grid.height / 2 } == true)
    }

    @Test(arguments: [3, 4])
    func fallBackBlocksMatchTheirWallClockLabel(_ hour: Int) {
        let key = page(fallBack.month, fallBack.day)
        let grid = layout([activity("a", zone.date(2026, 11, 1, hour), zone.date(2026, 11, 1, hour, 30))], on: key)
        #expect(grid.days[key]?.first?.top == grid.rowAt(labelRow(hour))?.top)
    }

    @Test(arguments: [3, 4, 5])
    func springForwardBlocksMatchTheirWallClockLabel(_ hour: Int) {
        let key = page(springForward.month, springForward.day)
        let grid = layout([activity("a", zone.date(2026, 3, 8, hour), zone.date(2026, 3, 8, hour, 30))], on: key)
        let a = grid.days[key]?.first
        #expect(a?.top == grid.rowAt(labelRow(hour))?.top)
        #expect(a.map { $0.top < $0.bottom } == true)
    }

    @Test func eveningBlocksKeepTheirLabelOnBothDays() {
        for (m, d) in [fallBack, springForward] {
            let key = page(m, d)
            let grid = layout([activity("a", zone.date(2026, m, d, 22), zone.date(2026, m, d, 23))], on: key)
            #expect(grid.days[key]?.first?.top == grid.rowAt(labelRow(22))?.top)
        }
    }

    @Test func noBlockSpansTheWholeGrid() {
        let key = page(fallBack.month, fallBack.day)
        let blocks = (0 ..< 6).map { h in
            activity("a\(h)", zone.date(2026, 11, 1, h, 10), zone.date(2026, 11, 1, h, 40))
        }
        let grid = layout(blocks, on: key)
        let laid = grid.days[key] ?? []
        #expect(laid.count == blocks.count)
        #expect(laid.allSatisfy { $0.top < $0.bottom && $0.bottom - $0.top < grid.height / 2 })
    }

    @Test func itemAtTheGridEndBelongsToTheLastRow() {
        let rows = CalendarNightFold.rows(busy: [], rowMinutes: 60, metrics: Split.day)
        let end = zone.date(2026, 11, 17, 6)
        let b = CalendarLaidBlock(block: activity("end", end, end), span: DateInterval(start: end, end: end), half: .actual)
        let item = CalendarSplitRows.Item(laid: b, day: 0, from: Limits.minutesPerDay, to: Limits.minutesPerDay)
        let placed = CalendarSplitRows.place([item], rows: rows, metrics: Split.day)
        #expect(placed.items.first?.laid.top == Double(Limits.minutesPerDay))
    }
}
