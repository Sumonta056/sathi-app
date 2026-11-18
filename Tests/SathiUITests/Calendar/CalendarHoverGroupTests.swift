import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar hover card for groups")
struct CalendarHoverGroupTests {
    typealias Fix = CalendarHoverFixtures

    private static func act(_ id: String, _ from: Int, _ to: Int) -> CalendarBlock {
        let a = Activity(text: id, start: day(2026, 3, 4, 10, from), end: day(2026, 3, 4, 10, to))
        return CalendarBlock(
            id: id, title: id, interval: a.interval, style: .activity(category: nil),
            source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        )
    }

    private let members: [CalendarBlock] = [act("Mail", 0, 5), act("Code", 5, 12), act("Docs", 12, 18)]

    private var group: CalendarPlacedBlock {
        CalendarPlacedBlock(block: CalendarBlockGroup.block(members), lane: 0, lanes: 1)
    }

    @Test func aMemberRowDoesWhatAClickOnThatBlockDoes() {
        let h = Fix.harness()
        let spy = Fix.Spy()
        Fix.runner(h, spy).open(row: "Code", Fix.target(group))
        #expect(spy.opened == ["Code"])
    }

    @Test func aCommandClickOnAMemberRowTogglesItForMerge() {
        let h = Fix.harness()
        let spy = Fix.Spy()
        spy.command = true
        Fix.runner(h, spy).open(row: "Docs", Fix.target(group))
        #expect(spy.toggled == members[2].activityIDs)
    }

    @Test func aChildRowOfAHostOpensThatChild() throws {
        let h = Fix.harness()
        let spy = Fix.Spy()
        var host = try Fix.placed(h, "Standup")
        host.children = [CalendarPlacedBlock(block: Self.act("Notes", 0, 20), lane: 0, lanes: 1, hostID: host.block.id)]
        Fix.runner(h, spy).open(row: "Notes", Fix.target(host))
        #expect(spy.opened == ["Notes"])
    }
}
