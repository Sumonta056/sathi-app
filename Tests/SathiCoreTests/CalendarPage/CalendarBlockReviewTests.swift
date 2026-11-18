import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlock option A review fixes")
struct CalendarBlockReviewTests {
    @Test func aLongActivityThatHoldsShortOnesStaysItsOwnBlock() {
        let placed = Grp.place([Grp.act("long", 0, 480), Grp.act("s1", 60, 65), Grp.act("s2", 66, 70), Grp.act("n", 82, 120)])
        #expect(Grp.groups(placed) == [["s1", "s2"]])
        #expect(Lay.byID(placed)["long"]?.block.group == nil)
    }

    @Test func overlappingShortActivitiesAreNotARun() {
        #expect(Grp.groups(Grp.place([Grp.act("a", 0, 8), Grp.act("b", 5, 13)])) == [])
    }

    @Test func aShortActivityNeverTakesALongOneItOverlaps() {
        #expect(Grp.groups(Grp.place([Grp.act("s", 0, 5), Grp.act("big", 3, 300)])) == [])
    }

    @Test func sameTitlesStillTakeTheFillOfTheLongestMember() {
        let first = Grp.act("a", 0, 3, title: "Testing", category: "Office")
        let b = CalendarBlockGroup.block([first, Grp.act("b", 3, 12, title: "Testing", category: "Work")])
        #expect(b.title == "Testing")
        #expect(b.style == .activity(category: "Work"))
        #expect(b.source == first.source)
    }

    @Test func aJoinedLongestMemberKeepsTheJoinedLook() {
        var long = Grp.act("b", 3, 12, title: "Code", category: "Work")
        long.style = .joined(category: "Work")
        let b = CalendarBlockGroup.block([Grp.act("a", 0, 3, title: "Mail", category: "Office"), long, Grp.act("c", 12, 20, title: "Docs")])
        #expect(b.style == .joined(category: "Work"))
    }

    @Test func theGroupIDFollowsTheLongestMemberAndTheColumn() {
        let b = CalendarBlockGroup.block([Grp.act("a", 0, 3), Grp.act("b", 3, 12)], column: "c1")
        #expect(b.id == "g-c1-b")
        let grown = CalendarBlockGroup.block([Grp.act("z", 0, 2), Grp.act("a", 2, 5), Grp.act("b", 5, 14)], column: "c1")
        #expect(grown.id == b.id)
    }

    @Test func anActivityCrossingTheDayStartGivesEachColumnItsOwnGroupID() {
        let day1 = Lay.span(0, 1440)
        let day2 = Lay.span(1440, 2880)
        let blocks = [Grp.act("x", 1420, 1428), Grp.act("a", 1430, 1445), Grp.act("b", 1445, 1450)]
        let one = CalendarBlockLayout.place(blocks, within: day1, minimumMinutes: Grp.least).filter { $0.block.group != nil }
        let two = CalendarBlockLayout.place(blocks, within: day2, minimumMinutes: Grp.least).filter { $0.block.group != nil }
        #expect(one.count == 1)
        #expect(two.count == 1)
        #expect(one.first?.block.id != two.first?.block.id)
    }

    @Test func theGroupKindLabelIsNeutral() {
        #expect(Copywriter.calendarHoverKind(.group) == "Grouped activities")
    }
}
