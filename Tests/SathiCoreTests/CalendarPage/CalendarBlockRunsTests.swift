import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockRuns short runs")
struct CalendarBlockRunsTests {
    @Test func backToBackShortActivitiesBecomeOneGroupAtTheirRealTime() {
        let placed = Grp.place([Grp.act("a", 0, 8), Grp.act("b", 8, 16), Grp.act("c", 16, 24), Grp.act("d", 60, 120)])
        #expect(Grp.groups(placed) == [["a", "b", "c"]])
        let group = placed.first { $0.block.group != nil }
        #expect(group?.span == Lay.span(0, 24))
        #expect(group?.block.interval == Lay.span(0, 24))
        #expect(group?.displaySpan == Lay.span(0, 26))
        #expect(Lay.byID(placed)["d"]?.displaySpan == Lay.span(60, 120))
    }

    @Test func aGapOfFiveMinutesStillJoinsARun() {
        #expect(Grp.groups(Grp.place([Grp.act("a", 0, 8), Grp.act("b", 13, 21)])) == [["a", "b"]])
    }

    @Test func aGapOverFiveMinutesSplitsTheRun() {
        #expect(Grp.groups(Grp.place([Grp.act("a", 0, 8), Grp.act("b", 14, 22)])) == [])
    }

    @Test func aSingleShortActivityStaysASingleBlock() {
        let r = Grp.shown([Grp.act("a", 0, 8), Grp.act("b", 60, 120)])
        #expect(r["a"]?.block.group == nil)
        #expect(r["a"]?.displaySpan == Lay.span(0, 26))
    }

    @Test func aShortRunThatWouldPushTakesTheNextNeighbour() {
        let placed = Grp.place([Grp.act("a", 0, 8), Grp.act("b", 10, 70)])
        #expect(Grp.groups(placed) == [["a", "b"]])
        #expect(placed.first?.span == Lay.span(0, 70))
    }

    @Test func theNextNeighbourMayBeTenMinutesAway() {
        #expect(Grp.groups(Grp.place([Grp.act("a", 0, 8), Grp.act("b", 18, 70)])) == [["a", "b"]])
    }

    @Test func aNeighbourOverTenMinutesAwayIsNotTaken() {
        #expect(Grp.groups(Grp.place([Grp.act("a", 0, 8), Grp.act("b", 19, 70)])) == [])
    }

    @Test func thePreviousNeighbourIsTakenWhenTheNextIsTooFar() {
        let placed = Grp.place([Grp.act("p", 0, 60), Grp.act("s", 61, 65), Grp.act("n", 80, 140)])
        #expect(Grp.groups(placed) == [["p", "s"]])
    }

    @Test func aRunThatPushesNothingTakesNoNeighbour() {
        #expect(Grp.groups(Grp.place([Grp.act("p", 0, 60), Grp.act("s", 61, 65), Grp.act("n", 95, 140)])) == [])
    }

    @Test func aRunAsLongAsTheMinimumTakesNoNeighbour() {
        let placed = Grp.place([Grp.act("a", 0, 15), Grp.act("b", 15, 27), Grp.act("c", 28, 90)])
        #expect(Grp.groups(placed) == [["a", "b"]])
    }

    @Test func eventsAwayAndTheRunningActivityNeverJoinARun() {
        let blocks = [
            Lay.event("e1", 200, 208), Lay.event("e2", 208, 216),
            Grp.act("a", 0, 8), Lay.away("w", 8, 10), Grp.act("b", 10, 18),
            Grp.act("f", 400, 408), Grp.act("r", 408, 412, running: true)
        ]
        let placed = Grp.place(blocks)
        #expect(Grp.groups(placed) == [["a", "b"]])
        #expect(Lay.byID(placed)["w"]?.isBackdrop == true)
        #expect(Lay.byID(placed)["r"]?.block.group == nil)
    }

    @Test func childrenOfAHostGroupInsideTheirHost() {
        let host = Grp.shown([Lay.event("e", 0, 60), Grp.act("a", 2, 8), Grp.act("b", 8, 14), Grp.act("c", 14, 20)])["e"]
        #expect(host?.children.count == 1)
        #expect(host?.children.first?.block.group?.members.map(\.id) == ["a", "b", "c"])
        #expect(host?.children.first?.hostID == "e")
    }

    @Test func noMinimumMeansNoGroups() {
        let placed = CalendarBlockLayout.place([Grp.act("a", 0, 8), Grp.act("b", 8, 16)], minimumMinutes: 0)
        #expect(Grp.groups(placed) == [])
    }

    @Test func noBlockIsLost() {
        let blocks = [
            Lay.event("e", 0, 60), Grp.act("a", 2, 8), Grp.act("b", 8, 14), Grp.act("c", 70, 74), Grp.act("d", 75, 79),
            Grp.act("f", 80, 200), Grp.act("g", 201, 203)
        ]
        #expect(Grp.everyID(Grp.place(blocks)) == Set(blocks.map(\.id)))
    }
}
