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

    private func laid(_ b: CalendarBlock) -> CalendarLaidBlock {
        var half = CalendarHalf.plan
        if case .activity = b.source { half = .actual }
        return CalendarLaidBlock(block: b, span: b.interval, half: half, rounded: CalendarRounding.rounded(b.interval))
    }

    private func hover(_ h: EngineHarness, _ b: CalendarBlock, among: [CalendarLaidBlock] = []) -> CalendarHoverInfo {
        h.engine.calendarHoverInfo(laid(b), among: among)
    }

    private func info(_ actions: [CalendarHoverAction] = []) -> CalendarHoverInfo {
        CalendarHoverInfo(id: "x", kind: .event, kindLabel: "K", title: "T", time: "9:00", length: nil, meta: nil, actions: actions)
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
        let info = try hover(h, Fix.block(h, "Standup"))
        let sut = try card(info)
        for line in ["Calendar event · Plan", "Standup", "Gmail Work", "9:00 – 9:30 AM · 30m"] {
            #expect(throws: Never.self) { try sut.find(text: line) }
        }
        expectButtons(sut, ["Start as activity", "Edit", "Open in Calendar"], hidden: ["Merge", "Delete", "Select all"])
    }

    @Test func readOnlyEventHasNoEdit() throws {
        let h = Fix.harness(at: day(2026, 3, 4, 9, 10), events: [Fix.standup(repeating: true)])
        let sut = try card(hover(h, Fix.block(h, "Standup")))
        expectButtons(sut, ["Start as activity", "Open in Calendar"], hidden: ["Edit"])
    }

    @Test func activityShowsItsKindCategoryAndEditDelete() throws {
        let h = Fix.harness()
        let sut = try card(hover(h, Fix.block(h, "Write")))
        #expect(throws: Never.self) { try sut.find(text: "Activity · Actual") }
        #expect(throws: Never.self) { try sut.find(text: "Coding") }
        expectButtons(sut, ["Edit", "Delete"], hidden: ["Merge", "Select all", "Start as activity", "Open in Calendar"])
    }

    @Test func todoShowsItsKindAndButtons() throws {
        let h = Fix.harness()
        let sut = try card(hover(h, Fix.todo()))
        #expect(throws: Never.self) { try sut.find(text: "To-do · Apple Reminders") }
        #expect(throws: Never.self) { try sut.find(text: "Call Rina") }
        expectButtons(sut, ["Mark done", "Edit", "Open in Reminders"], hidden: ["Delete", "Merge"])
    }

    @Test func awayShowsItsKindAndOnlyEditAway() throws {
        let h = Fix.harness()
        let sut = try card(hover(h, Fix.away()))
        #expect(throws: Never.self) { try sut.find(text: "Away") }
        expectButtons(sut, ["Edit Away"], hidden: ["Edit", "Merge", "Delete"])
    }

    @Test func noCardHasMergeOrSelectAllText() throws {
        let h = Fix.harness(at: day(2026, 3, 4, 9, 10))
        for b in try [Fix.block(h, "Standup"), Fix.block(h, "Write"), Fix.todo(), Fix.away()] {
            let sut = try card(hover(h, b))
            #expect(throws: (any Error).self) { try sut.find(text: "Merge") }
            #expect(throws: (any Error).self) { try sut.find(text: "Select all") }
        }
    }

    @Test func eventListsItsDoneDuringActivityAndATapPicksIt() throws {
        let h = Fix.harness()
        var picked: [String] = []
        let event = try Fix.block(h, "Standup")
        var write = try laid(Fix.block(h, "Write"))
        write.doneDuring = event.id
        let sut = try card(hover(h, event, among: [write]), pick: { picked.append($0) })
        #expect(throws: Never.self) { try sut.find(text: "Done during this event") }
        #expect(throws: Never.self) { try sut.find(text: "Write") }
        #expect(throws: Never.self) { try sut.find(text: "10:00 – 10:30 AM") }
        try sut.find(viewWithAccessibilityIdentifier: "calendar.hover.done." + write.id).button().tap()
        #expect(picked == [write.id])
    }

    @Test func cardWithNoDoneDuringHasNoDoneDuringTitle() throws {
        let h = Fix.harness()
        let sut = try card(hover(h, Fix.block(h, "Standup")))
        #expect(throws: (any Error).self) { try sut.find(text: "Done during this event") }
    }

    @Test(arguments: CalendarHoverAction.allCases)
    func eachButtonRunsItsAction(_ action: CalendarHoverAction) throws {
        var ran: [CalendarHoverAction] = []
        try card(info([action])) { ran.append($0) }.find(button: Copywriter.calendarHoverAction(action)).tap()
        #expect(ran == [action])
    }

    @Test func cardHasABorderAndNoShadow() throws {
        let h = Fix.harness()
        let sut = try card(hover(h, Fix.block(h, "Standup")))
        let root = try sut.find(viewWithAccessibilityIdentifier: "calendar.hover.card")
        #expect(throws: (any Error).self) { try root.shadow() }
    }

    @Test func alsoHereListsTheHiddenItemsAndATapPicksOne() throws {
        let h = Fix.harness()
        var picked: [String] = []
        var top = try laid(Fix.block(h, "Standup"))
        let hidden = try laid(Fix.block(h, "Write"))
        top.hidden = [hidden]
        let sut = try card(h.engine.calendarHoverInfo(top, among: []), pick: { picked.append($0) })
        #expect(throws: Never.self) { try sut.find(text: "Also here") }
        #expect(throws: Never.self) { try sut.find(text: "10:00 – 10:30 AM") }
        try sut.find(viewWithAccessibilityIdentifier: "calendar.hover.also." + hidden.id).button().tap()
        #expect(picked == [hidden.id])
    }
}
