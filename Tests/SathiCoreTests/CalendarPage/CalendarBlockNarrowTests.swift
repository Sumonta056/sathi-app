import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockLayout narrow lanes")
struct CalendarBlockNarrowTests {
    private let blocks = [Lay.event("e", 0, 30), Grp.act("a", 2, 10), Grp.act("b", 12, 28), Grp.act("n", 31, 90)]

    @Test func aWideHostShowsItsChildrenAndGrows() {
        let r = Grp.shown(blocks)
        #expect(r["e"]?.kidsShown == true)
        #expect((r["e"]?.displaySpan.end ?? Lay.at(0)) > Lay.at(30))
    }

    @Test func aNarrowHostHidesItsChildrenAndKeepsItsRealHeight() {
        let r = Grp.shown(blocks, narrow: [CalendarLaneShape(depth: 0, lanes: 1)])
        #expect(r["e"]?.kidsShown == false)
        #expect(r["e"]?.displaySpan == Lay.span(0, 30))
        #expect(r["e"]?.children.isEmpty == false)
        #expect(r["n"]?.displaySpan == Lay.span(31, 90))
    }

    @Test func aShapeThatIsNotNarrowKeepsTheChildren() {
        #expect(Grp.shown(blocks, narrow: [CalendarLaneShape(depth: 0, lanes: 2)])["e"]?.kidsShown == true)
    }
}
