import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar month grid")
struct CalendarMonthGridTests {
    private final class Box {
        var range: CalendarPageRange
        init(_ range: CalendarPageRange) { self.range = range }
        var binding: Binding<CalendarPageRange> { Binding(get: { self.range }, set: { self.range = $0 }) }
    }

    private let cal = Calendar.current
    private var month: CalendarPageRange { .containing(day(2026, 11, 12, 10), kind: .month, calendar: cal) }

    private func event(_ n: Int) -> CalendarBlock {
        let s = day(2026, 11, 12, 9 + n)
        let e = s.addingTimeInterval(1800)
        return CalendarBlock(
            id: "e\(n)", title: "Event \(n)", interval: DateInterval(start: s, end: e), style: .event(colorHex: 0x4285F4),
            source: .event(CalendarEventInfo(id: "e\(n)", title: "Event \(n)", start: s, end: e, calendarID: "c")),
            isAllDay: false, activityIDs: []
        )
    }

    private func grid(_ box: Box, events: Int = 5) throws -> InspectableView<ViewType.ClassifiedView> {
        let cells = CalendarMonthCell.cells(
            range: month, blocks: (0 ..< events).map(event), activities: [],
            today: DayKey(day(2026, 11, 12), calendar: cal), calendar: cal
        )
        return try CalendarMonthGrid(cells: cells, range: box.binding, calendar: cal).inspect()
    }

    @Test func showsThreeChipsThenMore() throws {
        let sut = try grid(Box(month))
        #expect(throws: Never.self) { try sut.find(text: "Event 2") }
        #expect(Find.lacks(sut, text: "Event 3"))
        #expect(throws: Never.self) { try sut.find(text: "+2 more") }
    }

    @Test func tapOnADateOpensItsDayView() throws {
        let box = Box(month)
        try grid(box).find(viewWithAccessibilityIdentifier: "calendar.month.2026-11-20").button().tap()
        #expect(box.range == .containing(day(2026, 11, 20, 12), kind: .day, calendar: cal))
    }

    @Test func todayIsHighlighted() throws {
        let sut = try grid(Box(month), events: 0)
        let today = try sut.find(viewWithAccessibilityIdentifier: "calendar.month.today")
        #expect(throws: Never.self) { try today.find(text: "12") }
        #expect(sut.findAll(where: { (try? $0.accessibilityIdentifier()) == "calendar.month.today" }).count == 1)
    }

    @Test func showsTheWeekdayHeader() throws {
        let sut = try grid(Box(month), events: 0)
        let first = month.monthWeeks[0][0]
        #expect(throws: Never.self) { try sut.find(text: Copywriter.calendarWeekday(first, calendar: cal)) }
    }
}
