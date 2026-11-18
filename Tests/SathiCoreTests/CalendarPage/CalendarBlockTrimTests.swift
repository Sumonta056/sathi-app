import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockNudge trim")
struct CalendarBlockTrimTests {
    @Test func theNextBlockShrinksFromTheTopAndKeepsItsRealEnd() {
        let r = Grp.shown([Grp.act("a", 0, 8), Grp.act("b", 20, 80)])
        #expect(r["a"]?.displaySpan == Lay.span(0, 26))
        #expect(r["b"]?.displaySpan == Lay.span(26, 80))
        #expect(r["b"]?.span == Lay.span(20, 80))
    }

    @Test func aTrimmedBlockIsNeverShorterThanTheMinimum() {
        let r = Grp.shown([Grp.act("a", 0, 8), Grp.act("b", 20, 45)])
        #expect(r["b"]?.displaySpan == Lay.span(26, 52))
    }

    @Test func aTrimmedEventKeepsItsRealEnd() {
        let r = Grp.shown([Grp.act("a", 0, 8), Lay.event("e", 20, 90)])
        #expect(r["e"]?.displaySpan == Lay.span(26, 90))
    }

    @Test func aBlockThatIsNotInTheWayKeepsItsTime() {
        let r = Grp.shown([Grp.act("a", 0, 8), Grp.act("b", 40, 100)])
        #expect(r["b"]?.displaySpan == Lay.span(40, 100))
    }
}
