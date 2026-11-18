import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar hover card")
struct CalendarHoverCardTests {
    typealias Fix = CalendarHoverFixtures

    private func card(
        _ info: CalendarHoverInfo, run: @escaping (CalendarHoverAction) -> Void = { _ in }, pick: @escaping (String) -> Void = { _ in }
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        try CalendarHoverCard(info: info, actions: info.actions, run: run, pick: pick).inspect()
    }

    private func expectButtons(_ sut: InspectableView<ViewType.ClassifiedView>, _ shown: [String], hidden: [String] = []) {
        for name in shown {
            #expect(throws: Never.self) { try sut.find(button: name) }
        }
        for name in hidden {
            #expect(throws: (any Error).self) { try sut.find(button: name) }
        }
    }

    @Test func eventShowsItsKindTitleTimeMetaAndButtons() throws {
        let h = Fix.harness(at: day(2026, 3, 4, 9, 10))
        let info = try h.engine.calendarHoverInfo(Fix.placed(h, "Standup"))
        let sut = try card(info)
        for line in ["Calendar event · Plan", "Standup", "Gmail Work"] {
            #expect(throws: Never.self) { try sut.find(text: line) }
        }
        #expect(throws: Never.self) { try sut.find(text: info.time + " · " + (info.length ?? "")) }
        expectButtons(sut, ["Start as activity", "Edit", "Open in Calendar"], hidden: ["Merge", "Delete"])
    }

    @Test func readOnlyEventHasNoEdit() throws {
        let h = Fix.harness(at: day(2026, 3, 4, 9, 10), events: [Fix.standup(repeating: true)])
        let sut = try card(h.engine.calendarHoverInfo(Fix.placed(h, "Standup")))
        expectButtons(sut, ["Start as activity", "Open in Calendar"], hidden: ["Edit"])
    }

    @Test func activityShowsItsKindCategoryAndButtons() throws {
        let h = Fix.harness()
        let sut = try card(h.engine.calendarHoverInfo(Fix.placed(h, "Write")))
        #expect(throws: Never.self) { try sut.find(text: "Activity · Actual") }
        #expect(throws: Never.self) { try sut.find(text: "Coding") }
        expectButtons(sut, ["Edit", "Merge", "Delete"], hidden: ["Start as activity", "Open in Calendar"])
    }

    @Test func todoShowsItsKindAndButtons() throws {
        let h = Fix.harness()
        let sut = try card(h.engine.calendarHoverInfo(CalendarPlacedBlock(block: Fix.todo(), lane: 0, lanes: 1)))
        #expect(throws: Never.self) { try sut.find(text: "To-do · Apple Reminders") }
        #expect(throws: Never.self) { try sut.find(text: "Call Rina") }
        expectButtons(sut, ["Mark done", "Edit", "Open in Reminders"], hidden: ["Delete"])
    }

    @Test func awayShowsItsKindAndOnlyEditAway() throws {
        let h = Fix.harness()
        let sut = try card(h.engine.calendarHoverInfo(CalendarPlacedBlock(block: Fix.away(), lane: 0, lanes: 1)))
        #expect(throws: Never.self) { try sut.find(text: "Away") }
        expectButtons(sut, ["Edit Away"], hidden: ["Edit", "Merge", "Delete"])
    }

    @Test func hostListsItsChildren() throws {
        let h = Fix.harness()
        var host = try Fix.placed(h, "Standup")
        host.children = try [CalendarPlacedBlock(block: Fix.block(h, "Write"), lane: 0, lanes: 1, hostID: host.block.id)]
        let sut = try card(h.engine.calendarHoverInfo(host))
        #expect(throws: Never.self) { try sut.find(text: "Done in this event") }
        #expect(throws: Never.self) { try sut.find(text: "Write") }
    }

    @Test func cardWithNoChildrenHasNoChildrenTitle() throws {
        let h = Fix.harness()
        let sut = try card(h.engine.calendarHoverInfo(Fix.placed(h, "Standup")))
        #expect(throws: (any Error).self) { try sut.find(text: "Done in this event") }
    }

    @Test(arguments: CalendarHoverAction.allCases)
    func eachButtonRunsItsAction(_ action: CalendarHoverAction) throws {
        var ran: [CalendarHoverAction] = []
        let info = CalendarHoverInfo(
            id: "x", kind: .event, kindLabel: "K", title: "T", time: "9:00", length: nil, meta: nil,
            childrenTitle: nil, children: [], actions: [action]
        )
        try card(info) { ran.append($0) }.find(button: Copywriter.calendarHoverAction(action)).tap()
        #expect(ran == [action])
    }

    @Test func cardHasABorderAndNoShadow() throws {
        let h = Fix.harness()
        let sut = try card(h.engine.calendarHoverInfo(Fix.placed(h, "Standup")))
        let root = try sut.find(viewWithAccessibilityIdentifier: "calendar.hover.card")
        #expect(throws: (any Error).self) { try root.shadow() }
    }

    @Test func alsoHereListsTheHiddenBlocksAndATapPicksOne() throws {
        var picked: [String] = []
        let info = CalendarHoverInfo(
            id: "x", kind: .event, kindLabel: "K", title: "T", time: "9:00", length: nil, meta: nil,
            childrenTitle: nil, children: [], alsoHereTitle: "Also here",
            alsoHere: [CalendarHoverChild(id: "r", title: "Review", time: "9:10 – 9:40 AM")], actions: []
        )
        let sut = try card(info, pick: { picked.append($0) })
        #expect(throws: Never.self) { try sut.find(text: "Also here") }
        #expect(throws: Never.self) { try sut.find(text: "9:10 – 9:40 AM") }
        try sut.find(viewWithAccessibilityIdentifier: "calendar.hover.also.r").button().tap()
        #expect(picked == ["r"])
    }
}
