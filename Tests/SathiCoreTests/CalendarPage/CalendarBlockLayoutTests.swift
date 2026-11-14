import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("CalendarBlockLayout")
struct CalendarBlockLayoutTests {
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func block(_ id: String, _ from: Int, _ to: Int, allDay: Bool = false) -> CalendarBlock {
        CalendarBlock(
            id: id, title: id,
            interval: DateInterval(start: t0.addingTimeInterval(TimeInterval(from * 60)), end: t0.addingTimeInterval(TimeInterval(to * 60))),
            style: .away,
            source: .event(CalendarEventInfo(id: id, title: id, start: t0, end: t0, calendarID: "c")),
            isAllDay: allDay, activityIDs: []
        )
    }

    func lanes(_ blocks: [CalendarBlock]) -> [String: [Int]] {
        Dictionary(uniqueKeysWithValues: CalendarBlockLayout.place(blocks).map { ($0.block.id, [$0.lane, $0.lanes]) })
    }

    @Test func twoOverlappingBlocksShareTwoLanes() {
        let result = lanes([block("a", 0, 30), block("b", 10, 40)])
        #expect(result["a"] == [0, 2])
        #expect(result["b"] == [1, 2])
    }

    @Test func laterBlockStartsANewCluster() {
        let result = lanes([block("a", 0, 30), block("b", 10, 40), block("c", 60, 90)])
        #expect(result["c"] == [0, 1])
    }

    @Test func touchingBlocksDoNotOverlap() {
        let result = lanes([block("a", 0, 30), block("b", 30, 60)])
        #expect(result["a"] == [0, 1])
        #expect(result["b"] == [0, 1])
    }

    @Test func chainReusesTheFirstLane() {
        let result = lanes([block("a", 0, 30), block("b", 20, 50), block("c", 40, 70)])
        #expect(result["a"] == [0, 2])
        #expect(result["b"] == [1, 2])
        #expect(result["c"] == [0, 2])
    }

    @Test func allDayBlocksAreExcluded() {
        #expect(CalendarBlockLayout.place([block("a", 0, 30, allDay: true)]).isEmpty)
    }
}

@Suite("CalendarBlockLayout page-day cut")
struct CalendarBlockLayoutCutTests {
    let cal = FixedZone.berlin.calendar
    var z: FixedZone { FixedZone.berlin }

    func block(_ id: String, _ start: Date, _ end: Date, style: CalendarBlockStyle = .activity(category: nil)) -> CalendarBlock {
        CalendarBlock(
            id: id, title: id, interval: DateInterval(start: start, end: end), style: style,
            source: .event(CalendarEventInfo(id: id, title: id, start: start, end: end, calendarID: "c")),
            isAllDay: false, activityIDs: []
        )
    }

    func page(_ d: Int) -> DateInterval {
        CalendarPageDay.interval(of: DayKey(z.date(2026, 11, d), calendar: cal), calendar: cal)
    }

    @Test func blockAcrossSixAMIsCutForEachColumn() {
        let b = block("a", z.date(2026, 11, 12, 4), z.date(2026, 11, 12, 8))
        let wednesday = CalendarBlockLayout.place([b], within: page(11))
        let thursday = CalendarBlockLayout.place([b], within: page(12))
        #expect(wednesday.map(\.span) == [DateInterval(start: z.date(2026, 11, 12, 4), end: z.date(2026, 11, 12, 6))])
        #expect(thursday.map(\.span) == [DateInterval(start: z.date(2026, 11, 12, 6), end: z.date(2026, 11, 12, 8))])
        #expect(wednesday.first?.block.interval == b.interval)
    }

    @Test func joinedBlockAcrossSixAMIsCut() {
        let b = block("j", z.date(2026, 11, 12, 5, 30), z.date(2026, 11, 12, 7), style: .joined(category: "Work"))
        #expect(CalendarBlockLayout.place([b], within: page(12)).map(\.span.start) == [z.date(2026, 11, 12, 6)])
        #expect(CalendarBlockLayout.place([b], within: page(11)).map(\.span.end) == [z.date(2026, 11, 12, 6)])
    }

    @Test func blockOutsideTheColumnIsDropped() {
        let b = block("x", z.date(2026, 11, 12, 9), z.date(2026, 11, 12, 10))
        #expect(CalendarBlockLayout.place([b], within: page(11)).isEmpty)
    }

    @Test func zeroLengthBlockAtTheColumnStartStays() {
        let b = block("z", z.date(2026, 11, 12, 6), z.date(2026, 11, 12, 6))
        #expect(CalendarBlockLayout.place([b], within: page(12)).count == 1)
        #expect(CalendarBlockLayout.place([b], within: page(11)).isEmpty)
    }

    @Test func blockInsideKeepsItsSpan() {
        let b = block("i", z.date(2026, 11, 12, 9), z.date(2026, 11, 12, 10))
        #expect(CalendarBlockLayout.place([b], within: page(12)).map(\.span) == [b.interval])
    }
}
