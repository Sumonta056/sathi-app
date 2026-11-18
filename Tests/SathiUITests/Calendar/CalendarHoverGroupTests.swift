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

    @Test func groupCardListsTheMembersAndATapPicksOne() throws {
        let h = Fix.harness()
        var picked: [String] = []
        let info = h.engine.calendarHoverInfo(group)
        let sut = try CalendarHoverCard(info: info, actions: info.actions, run: { _ in }, pick: { picked.append($0) }).inspect()
        #expect(throws: Never.self) { try sut.find(text: "3 activities · grouped") }
        #expect(throws: Never.self) { try sut.find(text: "In this block") }
        #expect(throws: Never.self) { try sut.find(button: "Select all") }
        try sut.find(viewWithAccessibilityIdentifier: "calendar.hover.row.Code").button().tap()
        #expect(picked == ["Code"])
    }

    @Test func selectAllIsOnlyShownWhereMergeWorks() {
        let h = Fix.harness()
        let info = h.engine.calendarHoverInfo(group)
        #expect(CalendarHoverRun.visible(info, canMerge: true) == [.selectAll])
        #expect(CalendarHoverRun.visible(info, canMerge: false) == [])
    }

    @Test func selectAllAddsEveryMemberToTheMergeSelection() {
        let h = Fix.harness()
        var picked: [ActivityID] = []
        var grid = CalendarGridActions()
        grid.toggle = { _ in }
        grid.select = { picked += $0 }
        CalendarHoverRun(engine: h.engine, grid: grid) { _ in }.run(.selectAll, Fix.target(group))
        #expect(picked == members.flatMap(\.activityIDs))
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
