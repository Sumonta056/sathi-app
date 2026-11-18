import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar placed block rows for groups")
struct CalendarHoverInfoGroupTests {
    private let members: [CalendarBlock] = [
        Grp.act("a", 0, 5, title: "Mail", category: "Office"), Grp.act("b", 5, 13, title: "Code", category: "Work"),
        Grp.act("c", 13, 21, title: "Docs", category: nil)
    ]

    private var group: CalendarPlacedBlock {
        CalendarPlacedBlock(block: CalendarBlockGroup.block(members), lane: 0, lanes: 1)
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
