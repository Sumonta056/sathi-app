import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockGroup title and look")
struct CalendarBlockGroupTests {
    @Test func sameTitlesGiveThatTitleAndATimesBadge() {
        let b = CalendarBlockGroup.block([
            Grp.act("a", 0, 5, title: "Testing"), Grp.act("b", 5, 9, title: "Testing "), Grp.act("c", 9, 12, title: "Testing")
        ])
        #expect(b.title == "Testing")
        #expect(b.group?.badge == "×3")
        #expect(b.group?.detail == nil)
    }

    @Test func aLongestMemberWithSixtyPercentLeadsWithAPlusBadge() {
        let b = CalendarBlockGroup.block([Grp.act("x", 0, 6, title: "Code"), Grp.act("y", 6, 10, title: "Mail")])
        #expect(b.title == "Code")
        #expect(b.group?.badge == "+1")
        #expect(b.group?.detail == nil)
    }

    @Test func noLeadGivesACountTitleAndTheTwoLongestTitles() {
        let b = CalendarBlockGroup.block([
            Grp.act("a", 0, 5, title: "Mail"), Grp.act("b", 5, 13, title: "Code"), Grp.act("c", 13, 15, title: "Chat"),
            Grp.act("d", 15, 21, title: "Docs")
        ])
        #expect(b.title == "4 activities")
        #expect(b.group?.badge == nil)
        #expect(b.group?.detail == "Code · Docs")
    }

    @Test func theDetailNeverRepeatsATitle() {
        let b = CalendarBlockGroup.block([
            Grp.act("a", 0, 5, title: "Mail"), Grp.act("b", 5, 10, title: "Code"), Grp.act("c", 10, 15, title: "Mail"),
            Grp.act("d", 15, 19, title: "Chat")
        ])
        #expect(b.group?.detail == "Mail · Code")
    }

    @Test func colorIsTheLongestMembersCategoryAndDotsListEveryCategory() {
        let b = CalendarBlockGroup.block([
            Grp.act("a", 0, 4, title: "Mail", category: "Office"), Grp.act("b", 4, 12, title: "Code", category: "Work"),
            Grp.act("c", 12, 15, title: "Chat", category: "Office")
        ])
        #expect(b.style == .activity(category: "Work"))
        #expect(b.group?.categories == ["Office", "Work"])
    }

    @Test func blockSpansTheMembersAndHoldsEveryRow() {
        let members = [Grp.act("a", 0, 4), Grp.act("b", 6, 12)]
        let b = CalendarBlockGroup.block(members)
        #expect(b.id == "g-a")
        #expect(b.interval == Lay.span(0, 12))
        #expect(b.activityIDs == members.flatMap(\.activityIDs))
        #expect(b.group?.members.map(\.id) == ["a", "b"])
        #expect(b.source == members[1].source)
    }
}
