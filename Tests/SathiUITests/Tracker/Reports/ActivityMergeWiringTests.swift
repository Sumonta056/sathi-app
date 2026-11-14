import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity merge wiring")
struct ActivityMergeWiringTests {
    typealias Fix = ActivityViewSupport

    private final class Box {
        var selected: Set<ActivityID>
        var error: String?
        var editing: ActivityEditTarget?
        init(_ selected: Set<ActivityID> = []) { self.selected = selected }
        var selectedBinding: Binding<Set<ActivityID>> { Binding(get: { self.selected }, set: { self.selected = $0 }) }
        var errorBinding: Binding<String?> { Binding(get: { self.error }, set: { self.error = $0 }) }
        var editingBinding: Binding<ActivityEditTarget?> { Binding(get: { self.editing }, set: { self.editing = $0 }) }
    }

    private final class Counter {
        var checks = 0
        var clears = 0
    }

    private func actions(_ counter: Counter, in day: ActivityDay) -> ActivityDayActions {
        var a = ActivityDayActions()
        a.mergeCheck = { ids in
            counter.checks += 1
            return ManualMergeCheck.check(ids, dayRows: day.activities, calendar: Fix.calendar)
        }
        a.merge = { _ in .merged(day.activities[0].id) }
        a.clearMergeUndo = { counter.clears += 1 }
        return a
    }

    private func card(_ box: Box, _ a: ActivityDayActions, day: ActivityDay = Fix.day(), canUndo: Bool = false) -> ActivityTimelineCard {
        ActivityTimelineCard(
            day: day, count: ActivityDayStats(day).count, gaps: ActivityGaps.spans(day, now: .distantFuture, isTrackerDay: true),
            categories: ActivityCategory.defaults, calendar: Fix.calendar, calendars: Fix.calendars, calendarNames: [:],
            actions: a, canUndo: canUndo, editing: box.editingBinding, selected: box.selectedBinding, mergeError: box.errorBinding
        )
    }

    private var ids: Set<ActivityID> { Set(Fix.items.map(\.id)) }

    @Test func theBodyDoesNotRunTheCheckAgainForTheSameSelection() throws {
        let counter = Counter()
        let sut = card(Box(ids), actions(counter, in: Fix.day()))
        _ = try sut.inspect().find(ActivityMergeBar.self)
        _ = try sut.inspect().find(ActivityMergeBar.self)
        #expect(counter.checks == 1)
    }

    @Test func noCheckRunsWithNothingSelected() throws {
        let counter = Counter()
        let sut = card(Box(), actions(counter, in: Fix.day()))
        _ = try sut.inspect()
        #expect(counter.checks == 0)
        #expect(throws: (any Error).self) { try sut.inspect().find(ActivityMergeBar.self) }
    }

    @Test func aMergeEmptiesTheSelection() throws {
        let box = Box(ids)
        let sut = card(box, actions(Counter(), in: Fix.day()))
        try sut.inspect().find(button: "Merge").tap()
        #expect(box.selected.isEmpty)
    }

    @Test func tickingABoxKeepsUndoAndClearsTheError() throws {
        let counter = Counter()
        let box = Box()
        box.error = "old"
        let sut = card(box, actions(counter, in: Fix.day()), canUndo: true)
        try sut.inspect().findAll(ActivitySelectBox.self)[0].find(ViewType.Button.self).tap()
        #expect(box.selected == [Fix.items[0].id])
        #expect(box.error == nil)
        #expect(counter.clears == 0)
    }

    @Test func deletingASelectedRowDropsItFromTheSelection() throws {
        let block = Activity(kind: .timeBlock, text: "Focus", start: Fix.at(4, 12), end: Fix.at(4, 13))
        let day = Fix.day(4, Fix.items + [block])
        var a = actions(Counter(), in: day)
        a.delete = { _ in true }
        let box = Box([block.id, Fix.items[0].id])
        try Find.button(card(box, a, day: day).inspect(), label: "Delete Focus").tap()
        #expect(box.selected == [Fix.items[0].id])
    }

    @Test func pruneKeepsOnlyIdsOfCurrentRows() {
        let gone = Fix.item("Gone", "Coding", 4, (15, 0), (15, 30))
        let kept = ActivityMergeBar.pruned([Fix.items[0].id, gone.id], in: Fix.items)
        #expect(kept == [Fix.items[0].id])
    }

    @Test func aDayChangeClearsTheUndoAndTheSelectionHooks() throws {
        let counter = Counter()
        let view = ActivityDayView(
            day: Fix.day(), overview: ActivityDayOverview(Fix.day(), loggedChange: .up(0)), categories: ActivityCategory.defaults,
            calendar: Fix.calendar, calendars: Fix.calendars, actions: actions(counter, in: Fix.day())
        )
        try view.inspect().find(ViewType.HStack.self).callOnChange(newValue: Fix.key(5), index: 0)
        #expect(counter.clears == 1)
    }
}
