import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity merge bar")
struct ActivityMergeBarTests {
    typealias Fix = ActivityViewSupport

    private final class Box {
        var selected: Set<ActivityID>
        var error: String?
        init(_ selected: Set<ActivityID> = [], error: String? = nil) {
            self.selected = selected
            self.error = error
        }

        var selectedBinding: Binding<Set<ActivityID>> { Binding(get: { self.selected }, set: { self.selected = $0 }) }
        var errorBinding: Binding<String?> { Binding(get: { self.error }, set: { self.error = $0 }) }
    }

    private func plan(rows: Int) -> ManualMergePlan {
        let list = (0 ..< rows).map { i in
            Fix.item("Row \(i)", "Coding", 4, (10, i * 30), (10, i * 30 + (i == rows - 1 ? 30 : 20)))
        }
        let check = ManualMergeCheck.check(Set(list.map(\.id)), dayRows: list, calendar: Fix.calendar)
        guard case let .ok(plan) = check else { fatalError("fixture must merge") }
        return plan
    }

    private func bar(
        _ check: ManualMergeCheck?, _ box: Box, canUndo: Bool = false, actions: ActivityDayActions = ActivityDayActions()
    ) -> ActivityMergeBar {
        ActivityMergeBar(
            check: check, calendar: Fix.calendar, canUndo: canUndo, actions: actions,
            selected: box.selectedBinding, error: box.errorBinding
        )
    }

    private func plain(_ text: String) -> String { text.replacingOccurrences(of: "\u{202F}", with: " ") }

    private func press(_ sut: ActivityMergeBar, _ title: String) throws {
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: title) != nil }.tap()
    }

    @Test func aBlockedCheckTurnsTheButtonOffWithItsReason() {
        let state = ActivityMergeBar.state(.blocked(.namedAway), calendar: Fix.calendar)
        #expect(!state.enabled)
        #expect(state.line == Copywriter.mergeBlocked(.namedAway))
    }

    @Test func anOkCheckShowsThePreviewLine() {
        let state = ActivityMergeBar.state(.ok(plan(rows: 3)), calendar: Fix.calendar)
        #expect(state.enabled)
        #expect(plain(state.line) == "3 rows become 1, 10:00 AM to 11:30 AM")
    }

    @Test func theBarShowsTheLineAndTheMergeButton() throws {
        let sut = bar(.ok(plan(rows: 3)), Box())
        let line = ActivityMergeBar.state(.ok(plan(rows: 3)), calendar: Fix.calendar).line
        #expect(throws: Never.self) { try sut.inspect().find(text: line) }
        #expect(throws: Never.self) { try sut.inspect().find(button: "Merge") }
        #expect(try sut.inspect().find(button: "Merge").isDisabled() == false)
    }

    @Test func theMergeButtonIsOffWhenBlocked() throws {
        let sut = bar(.blocked(.rowBetween), Box())
        #expect(try sut.inspect().find(button: "Merge").isDisabled())
        #expect(throws: Never.self) { try sut.inspect().find(text: Copywriter.mergeBlocked(.rowBetween)) }
    }

    @Test func theMergeButtonCallsTheMergeAction() throws {
        let ids: Set<ActivityID> = Set(Fix.items.map(\.id))
        var called: Set<ActivityID>?
        var actions = ActivityDayActions()
        actions.merge = { called = $0; return .merged(Fix.items[0].id) }
        let box = Box(ids, error: "old")
        try press(bar(.ok(plan(rows: 2)), box, actions: actions), "Merge")
        #expect(called == ids)
        #expect(box.selected.isEmpty)
        #expect(box.error == nil)
    }

    @Test func aCalendarFailureKeepsTheSelectionAndShowsTheLine() throws {
        var actions = ActivityDayActions()
        actions.merge = { _ in .calendarFailed }
        let ids: Set<ActivityID> = Set(Fix.items.map(\.id))
        let box = Box(ids)
        try press(bar(.ok(plan(rows: 2)), box, actions: actions), "Merge")
        #expect(box.error == Copywriter.mergeCalendarFailed)
        #expect(box.selected == ids)
    }

    @Test func everyResultHasTheRightLine() {
        #expect(ActivityMergeBar.line(.merged(Fix.items[0].id)) == nil)
        #expect(ActivityMergeBar.line(.blocked(.tooFew)) == Copywriter.mergeBlocked(.tooFew))
        #expect(ActivityMergeBar.line(.calendarFailed) == Copywriter.mergeCalendarFailed)
        #expect(ActivityMergeBar.line(.calendarPartlyChanged) == Copywriter.mergeCalendarPartly)
        #expect(ActivityMergeBar.line(ManualMergeUndoResult.restored) == nil)
        #expect(ActivityMergeBar.line(ManualMergeUndoResult.gone) == nil)
        #expect(ActivityMergeBar.line(ManualMergeUndoResult.restoredCalendarFailed) == Copywriter.mergeUndoCalendarFailed)
    }

    @Test func theErrorLineShows() throws {
        let sut = bar(.ok(plan(rows: 2)), Box(error: Copywriter.mergeCalendarPartly))
        #expect(throws: Never.self) { try sut.inspect().find(text: Copywriter.mergeCalendarPartly) }
    }

    @Test func undoShowsOnlyWhileAnUndoIsPending() throws {
        #expect(throws: Never.self) { try bar(nil, Box(), canUndo: true).inspect().find(button: "Undo") }
        #expect(throws: (any Error).self) { try bar(nil, Box(), canUndo: false).inspect().find(button: "Undo") }
        #expect(throws: (any Error).self) { try bar(nil, Box(), canUndo: true).inspect().find(button: "Merge") }
    }

    @Test func undoCallsTheActionAndShowsAFailedCalendarLine() throws {
        var actions = ActivityDayActions()
        actions.undoMerge = { .restoredCalendarFailed }
        let box = Box()
        try press(bar(nil, box, canUndo: true, actions: actions), "Undo")
        #expect(box.error == Copywriter.mergeUndoCalendarFailed)
    }

    @Test func theBarHidesWhenThereIsNothingToShow() {
        #expect(!ActivityMergeBar.shows(selected: [], canUndo: false, error: nil))
        #expect(ActivityMergeBar.shows(selected: [Fix.items[0].id], canUndo: false, error: nil))
        #expect(ActivityMergeBar.shows(selected: [], canUndo: true, error: nil))
        #expect(ActivityMergeBar.shows(selected: [], canUndo: false, error: "x"))
    }
}

@MainActor
@Suite("Activity select boxes")
struct ActivitySelectBoxTests {
    typealias Fix = ActivityViewSupport

    private func list(selected: Set<ActivityID> = [], running: Bool = false, onToggle: @escaping (ActivityID) -> Void = { _ in
    }) -> ActivityTimelineList {
        let rows: [ActivityLogRow] = [
            .activity(Fix.items[0], running: false), .gap(DateInterval(start: Fix.at(4, 10, 30), end: Fix.at(4, 11))),
            .activity(Fix.items[1], running: running)
        ]
        return ActivityTimelineList(
            rows: rows, categories: ActivityCategory.defaults, calendar: Fix.calendar, selected: selected, onToggle: onToggle
        )
    }

    @Test func everyStoredRowHasASelectBox() throws {
        let sut = try list().inspect()
        #expect(sut.findAll(ActivitySelectBox.self).count == 2)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: "Select Fix login bug") }
    }

    @Test func theRunningRowHasNoBox() throws {
        let sut = try list(running: true).inspect()
        #expect(sut.findAll(ActivitySelectBox.self).count == 1)
        #expect(Find.lacks(sut, text: "Select Standup"))
    }

    @Test func aTapTogglesThatRow() throws {
        var toggled: ActivityID?
        let sut = try list { toggled = $0 }.inspect()
        try sut.findAll(ActivitySelectBox.self)[1].find(ViewType.Button.self).tap()
        #expect(toggled == Fix.items[1].id)
    }

    @Test func aSelectedRowShowsACheck() throws {
        let sut = try list(selected: [Fix.items[0].id]).inspect()
        let boxes = sut.findAll(ActivitySelectBox.self)
        #expect(try boxes[0].actualView().on)
        #expect(try !boxes[1].actualView().on)
    }
}
