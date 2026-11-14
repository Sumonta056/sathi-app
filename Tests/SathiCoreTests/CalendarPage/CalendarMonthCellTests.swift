import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("CalendarMonthCell")
struct CalendarMonthCellTests {
    let zone = FixedZone("Europe/Berlin", firstWeekday: 2)

    var march: CalendarPageRange { .containing(zone.date(2026, 3, 4, 12), kind: .month, calendar: zone.calendar) }

    func eventBlock(_ id: String, _ from: Date, minutes: Int = 30) -> CalendarBlock {
        let e = CalendarEventInfo(id: id, title: id, start: from, end: from.addingTimeInterval(TimeInterval(minutes * 60)), calendarID: "work")
        return CalendarBlock(
            id: EventRules.key(e), title: id, interval: DateInterval(start: e.start, end: e.end),
            style: .event(colorHex: 0), source: .event(e), isAllDay: false, activityIDs: []
        )
    }

    func cells(_ blocks: [CalendarBlock] = [], _ rows: [Activity] = [], today: DayKey? = nil) -> [CalendarMonthCell] {
        let t = today ?? DayKey(zone.date(2026, 3, 20), calendar: zone.calendar)
        return CalendarMonthCell.cells(range: march, blocks: blocks, activities: rows, today: t, calendar: zone.calendar).flatMap { $0 }
    }

    func cell(_ raw: String, in list: [CalendarMonthCell]) -> CalendarMonthCell? {
        list.first { $0.day.raw == raw }
    }

    @Test func fiveEventsGiveThreeChipsAndTwoMore() {
        let blocks = (0 ..< 5).map { eventBlock("e\($0)", zone.date(2026, 3, 4, 9 + $0)) }
        let c = cell("2026-03-04", in: cells(blocks))
        #expect(c?.chips.map(\.title) == ["e0", "e1", "e2"])
        #expect(c?.more == 2)
    }

    @Test func trackedUsesSixAMBoundary() {
        let rows = [
            Activity(text: "late", start: zone.date(2026, 3, 5, 0, 22), end: zone.date(2026, 3, 5, 2, 2)),
            Activity(text: "early", start: zone.date(2026, 3, 5, 5, 30), end: zone.date(2026, 3, 5, 6, 30))
        ]
        let list = cells([], rows)
        #expect(cell("2026-03-04", in: list)?.tracked == TimeInterval((100 + 30) * 60))
        #expect(cell("2026-03-05", in: list)?.tracked == TimeInterval(30 * 60))
    }

    @Test func todayIsFlagged() {
        let list = cells(today: DayKey(zone.date(2026, 3, 11), calendar: zone.calendar))
        #expect(cell("2026-03-11", in: list)?.isToday == true)
        #expect(list.filter(\.isToday).count == 1)
    }

    @Test func dateOutsideTheMonthHasNoChips() {
        let blocks = [eventBlock("feb", zone.date(2026, 2, 28, 10)), eventBlock("mar", zone.date(2026, 3, 1, 10))]
        let list = cells(blocks)
        let feb = cell("2026-02-28", in: list)
        #expect(feb?.inRange == false)
        #expect(feb?.chips.isEmpty == true)
        #expect(feb?.more == 0)
        #expect(cell("2026-03-01", in: list)?.inRange == true)
        #expect(cell("2026-03-01", in: list)?.chips.count == 1)
    }
}
