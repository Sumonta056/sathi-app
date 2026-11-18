import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar hover card info for groups")
struct CalendarHoverInfoGroupTests {
    private let cal = FixedZone.berlin.calendar

    private func info(_ placed: CalendarPlacedBlock) -> CalendarHoverInfo {
        CalendarHoverInfo.make(placed, lookup: CalendarHoverLookup(now: Lay.at(0), trackerOn: true), calendar: cal)
    }

    private let members: [CalendarBlock] = [
        Grp.act("a", 0, 5, title: "Mail", category: "Office"), Grp.act("b", 5, 13, title: "Code", category: "Work"),
        Grp.act("c", 13, 21, title: "Docs", category: nil)
    ]

    private var group: CalendarPlacedBlock {
        CalendarPlacedBlock(block: CalendarBlockGroup.block(members), lane: 0, lanes: 1)
    }

    @Test func groupShowsItsCountKindRealSpanAndCategories() {
        let i = info(group)
        #expect(i.kind == .group)
        #expect(i.kindLabel == "3 activities · grouped")
        #expect(i.title == "3 activities")
        #expect(i.time == Copywriter.trackerSpan(Lay.at(0), Lay.at(21), calendar: cal))
        #expect(i.length == Copywriter.trackerDuration(21 * Timing.minute))
        #expect(i.meta == "Office, Work, " + Copywriter.trackerNoCategory)
    }

    @Test func groupListsEveryMemberWithItsShortTime() {
        let i = info(group)
        #expect(i.childrenTitle == "In this block")
        #expect(i.children.map(\.id) == ["a", "b", "c"])
        #expect(i.children.map(\.title) == ["Mail", "Code", "Docs"])
        #expect(i.children.first?.time == Fmt.shortRange(Lay.at(0), Lay.at(5), calendar: cal))
    }

    @Test func groupOffersSelectAll() {
        #expect(info(group).actions == [.selectAll])
    }

    @Test func anEventListsTheMembersOfAGroupedChild() {
        var host = CalendarPlacedBlock(block: Lay.event("e", 0, 60), lane: 0, lanes: 1)
        host.children = [group, CalendarPlacedBlock(block: Grp.act("d", 30, 50), lane: 0, lanes: 1, hostID: "e")]
        host.kidsShown = false
        let i = info(host)
        #expect(i.childrenTitle == Copywriter.calendarHoverChildren)
        #expect(i.children.map(\.id) == ["a", "b", "c", "d"])
    }

    @Test func alsoHereListsTheMembersOfAHiddenGroup() {
        var top = CalendarPlacedBlock(block: Lay.event("e", 0, 60), lane: 0, lanes: 1)
        top.hidden = [group]
        #expect(info(top).alsoHere.map(\.id) == ["a", "b", "c"])
    }

    @Test func aRowIDFindsItsBlockInMembersChildrenAndHidden() {
        var host = CalendarPlacedBlock(block: Lay.event("e", 0, 60), lane: 0, lanes: 1)
        host.children = [group]
        host.hidden = [CalendarPlacedBlock(block: Grp.act("h", 0, 9), lane: 0, lanes: 1)]
        #expect(host.row("b")?.title == "Code")
        #expect(host.row("h")?.id == "h")
        #expect(host.row("zz") == nil)
        #expect(group.row("c")?.id == "c")
    }

    @Test func mergeIDsOfAGroupAreEveryMemberRow() {
        #expect(group.block.mergeIDs == members.flatMap(\.activityIDs))
        let single = Grp.act("x", 0, 9)
        #expect(single.mergeIDs == single.activityIDs)
    }
}
