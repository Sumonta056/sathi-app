import Foundation
@testable import SathiCore
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
