import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity timeline edit")
final class ActivityTimelineEditTests {
    typealias Fix = ActivityViewSupport
    private var editing: ActivityEditTarget?

    private func content(_ actions: ActivityDayActions = ActivityDayActions()) -> ActivityTimelineContent {
        let day = Fix.day()
        return ActivityTimelineContent(
            day: day, count: ActivityDayStats(day).count, gaps: ActivityGaps.spans(day, now: .distantFuture, isTrackerDay: true),
            categories: ActivityCategory.defaults,
            calendar: Fix.calendar, calendars: Fix.calendars, calendarNames: [:], actions: actions,
            editing: Binding(get: { self.editing }, set: { self.editing = $0 })
        )
    }

    private func tapPencil(_ title: String, _ actions: ActivityDayActions = ActivityDayActions()) throws {
        try Find.button(content(actions).inspect(), label: "Edit " + title).tap()
    }

    private func selectedRows() throws -> [ActivityID] {
        try content().inspect().findAll(ActivityTimelineRow.self).map { try $0.actualView() }.filter(\.selected).map(\.activity.id)
    }

    @Test func aSecondPencilMovesTheOneEditSection() throws {
        try tapPencil("Fix login bug")
        #expect(editing == .activity(Fix.items[0].id))
        #expect(try selectedRows() == [Fix.items[0].id])
        try tapPencil("Standup")
        #expect(editing == .activity(Fix.items[1].id))
        #expect(try content().inspect().findAll(ActivityEditSection.self).count == 1)
        #expect(try selectedRows() == [Fix.items[1].id])
    }

    @Test func aFailedDeleteKeepsTheSectionOpen() throws {
        var actions = ActivityDayActions()
        actions.delete = { _ in false }
        editing = .activity(Fix.items[0].id)
        try content(actions).inspect().find(ActivityEditSection.self)
            .find(ViewType.Button.self) { try $0.labelView().find(text: "Delete") != nil }.tap()
        #expect(editing == .activity(Fix.items[0].id))
    }

    @Test func aDeleteThatWorksClosesTheSection() throws {
        var deleted: [ActivityID] = []
        var actions = ActivityDayActions()
        actions.delete = { deleted.append($0); return true }
        editing = .activity(Fix.items[0].id)
        try content(actions).inspect().find(ActivityEditSection.self)
            .find(ViewType.Button.self) { try $0.labelView().find(text: "Delete") != nil }.tap()
        #expect(deleted == [Fix.items[0].id])
        #expect(editing == nil)
    }
}
