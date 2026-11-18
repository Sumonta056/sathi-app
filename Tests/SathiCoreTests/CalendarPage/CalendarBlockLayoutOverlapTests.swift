import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockLayout overlap")
struct CalendarBlockLayoutOverlapTests {
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func block(_ id: String, _ from: Int, _ to: Int, style: CalendarBlockStyle = .event(colorHex: 0)) -> CalendarBlock {
        CalendarBlock(
            id: id, title: id,
            interval: DateInterval(start: t0.addingTimeInterval(TimeInterval(from * 60)), end: t0.addingTimeInterval(TimeInterval(to * 60))),
            style: style,
            source: .event(CalendarEventInfo(id: id, title: id, start: t0, end: t0, calendarID: "c")),
            isAllDay: false, activityIDs: []
        )
    }

    func away(_ id: String, _ from: Int, _ to: Int) -> CalendarBlock {
        block(id, from, to, style: .away)
    }

    func placed(_ blocks: [CalendarBlock]) -> [String: CalendarPlacedBlock] {
        Dictionary(uniqueKeysWithValues: CalendarBlockLayout.place(blocks).map { ($0.block.id, $0) })
    }

    func shape(_ p: CalendarPlacedBlock?) -> [Int]? {
        p.map { [$0.lane, $0.lanes, $0.depth] }
    }

    @Test func limitsMatchTheRule() {
        #expect(Limits.calendarSideBySideMinutes == 30)
        #expect(Limits.calendarCascadeMaxDepth == 2)
        #expect(Limits.calendarLanesMax == 2)
    }

    @Test func placedBlockDefaultsToDepthZeroAndNoBackdrop() {
        let p = CalendarPlacedBlock(block: block("a", 0, 30), lane: 0, lanes: 1)
        #expect(p.depth == 0)
        #expect(!p.isBackdrop)
        #expect(!p.isRaised)
        #expect(p.hostID == nil)
        #expect(p.children.isEmpty)
        #expect(p.hiddenCount == 0)
        #expect(p.displaySpan == p.span)
    }

    @Test func awayIsABackdropAndAddsNoLanes() {
        let result = placed([away("w", 0, 120), block("a", 10, 40)])
        #expect(result["w"]?.isBackdrop == true)
        #expect(shape(result["w"]) == [0, 1, 0])
        #expect(result["a"]?.isBackdrop == false)
        #expect(shape(result["a"]) == [0, 1, 0])
    }

    @Test func blockInsideAnAwayBackdropKeepsFullWidth() {
        let result = placed([away("w", 0, 180), block("a", 30, 60)])
        #expect(shape(result["a"]) == [0, 1, 0])
    }

    @Test func awayStartingFirstDoesNotPushALaterBlockIntoACascade() {
        let result = placed([away("w", 0, 180), block("a", 60, 90), block("b", 65, 100)])
        #expect(shape(result["a"]) == [0, 2, 0])
        #expect(shape(result["b"]) == [1, 2, 0])
    }

    @Test func blocksStartingCloseTogetherSitSideBySide() {
        let result = placed([block("a", 0, 60), block("b", 10, 70)])
        #expect(shape(result["a"]) == [0, 2, 0])
        #expect(shape(result["b"]) == [1, 2, 0])
    }

    @Test func blockStartingAtTheThresholdCascades() {
        let result = placed([block("a", 0, 60), block("b", 30, 45)])
        #expect(shape(result["a"]) == [0, 1, 0])
        #expect(shape(result["b"]) == [0, 1, 1])
    }

    @Test func blocksStartingTwentyThreeMinutesApartShareTwoLanes() {
        let result = placed([block("a", 0, 60), block("b", 23, 80)])
        #expect(shape(result["a"]) == [0, 2, 0])
        #expect(shape(result["b"]) == [1, 2, 0])
        #expect(result["b"]?.isRaised == false)
    }

    @Test func blocksStartingFourHoursApartGiveOneFullWidthAndOneRaised() {
        let result = placed([block("one", 780, 1080), block("five", 1020, 1080)])
        #expect(shape(result["one"]) == [0, 1, 0])
        #expect(result["one"]?.isRaised == false)
        #expect(shape(result["five"]) == [0, 1, 1])
        #expect(result["five"]?.isRaised == true)
    }

    @Test func thirdBlockInAGroupBecomesPlusOne() {
        let result = placed([block("a", 0, 60), block("b", 5, 60), block("c", 10, 60)])
        #expect(shape(result["a"]) == [0, 2, 0])
        #expect(shape(result["b"]) == [1, 2, 0])
        #expect(result["c"] == nil)
        #expect(result["a"]?.hiddenCount == 1)
        #expect(result["b"]?.hiddenCount == 0)
    }

    @Test func extraBlocksAddUpInOneChip() {
        let result = placed([block("a", 0, 60), block("b", 5, 60), block("c", 10, 60), block("d", 12, 60)])
        #expect(result.count == 2)
        #expect(result["a"]?.hiddenCount == 2)
    }

    @Test func laterStartOverAnOpenBlockSitsOnTop() {
        let result = placed([block("a", 0, 120), block("b", 30, 60)])
        #expect(shape(result["a"]) == [0, 1, 0])
        #expect(shape(result["b"]) == [0, 1, 1])
    }

    @Test func longerBlockFirstWhenStartsAreEqual() {
        let result = placed([block("short", 0, 30), block("long", 0, 90)])
        #expect(shape(result["long"]) == [0, 2, 0])
        #expect(shape(result["short"]) == [1, 2, 0])
    }

    @Test func nestedLaterStartsCapTheDepth() {
        let result = placed([
            block("a", 0, 300), block("b", 30, 300), block("c", 60, 300), block("d", 90, 300), block("e", 120, 300)
        ])
        #expect(result["a"]?.depth == 0)
        #expect(result["b"]?.depth == 1)
        #expect(result["c"]?.depth == 2)
        #expect(result["d"]?.depth == 2)
        #expect(result["e"]?.depth == 2)
    }

    @Test func chainOfLaterStartsCascades() {
        let result = placed([block("a", 0, 60), block("b", 40, 90), block("c", 80, 120)])
        #expect(shape(result["a"]) == [0, 1, 0])
        #expect(shape(result["b"]) == [0, 1, 1])
        #expect(shape(result["c"]) == [0, 1, 2])
    }

    @Test func cascadedGroupSharesItsDepthSideBySide() {
        let result = placed([block("a", 0, 120), block("b", 30, 60), block("c", 35, 70)])
        #expect(shape(result["b"]) == [0, 2, 1])
        #expect(shape(result["c"]) == [1, 2, 1])
        #expect(shape(result["a"]) == [0, 1, 0])
    }

    @Test func touchingBlocksStayAtDepthZero() {
        let result = placed([block("a", 0, 30), block("b", 30, 60)])
        #expect(shape(result["a"]) == [0, 1, 0])
        #expect(shape(result["b"]) == [0, 1, 0])
    }

    @Test func blockAfterEverythingEndedStartsAtDepthZero() {
        let result = placed([block("a", 0, 120), block("b", 30, 60), block("c", 130, 160)])
        #expect(shape(result["c"]) == [0, 1, 0])
    }

    @Test func columnPlacementAlsoMarksTheBackdrop() {
        let column = DateInterval(start: t0, end: t0.addingTimeInterval(24 * 3600))
        let result = CalendarBlockLayout.place([away("w", 0, 60), block("a", 30, 50)], within: column)
        #expect(result.first { $0.block.id == "w" }?.isBackdrop == true)
        #expect(result.first { $0.block.id == "a" }?.depth == 0)
    }
}
