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

    private var binding: Binding<ActivityEditTarget?> {
        Binding(get: { self.editing }, set: { self.editing = $0 })
    }

    private func content(_ actions: ActivityDayActions = ActivityDayActions()) -> ActivityTimelineCard {
        let day = Fix.day()
        return ActivityTimelineCard(
            day: day, count: ActivityDayStats(day).count, gaps: ActivityGaps.spans(day, now: .distantFuture, isTrackerDay: true),
            categories: ActivityCategory.defaults,
            calendar: Fix.calendar, calendars: Fix.calendars, calendarNames: [:], actions: actions, editing: binding,
            selected: .constant([]), mergeError: .constant(nil)
        )
    }

    private func panel(_ target: ActivityEditTarget, _ actions: ActivityDayActions = ActivityDayActions()) -> ActivityEditPanel {
        ActivityEditPanel(
            day: Fix.day(), target: target, categories: ActivityCategory.defaults, calendar: Fix.calendar,
            calendars: Fix.calendars, calendarNames: [:], actions: actions, editing: binding
        )
    }

    private func tapPencil(_ title: String, _ actions: ActivityDayActions = ActivityDayActions()) throws {
        try Find.button(content(actions).inspect(), label: "Edit " + title).tap()
    }

    private func selectedRows() throws -> [ActivityID] {
        try content().inspect().findAll(ActivityTimelineRow.self).map { try $0.actualView() }.filter(\.selected).map(\.activity.id)
    }

    private func tapDelete(_ sut: ActivityEditPanel) throws {
        try sut.inspect().find(ActivityEditSection.self)
            .find(ViewType.Button.self) { try $0.labelView().find(text: "Delete") != nil }.tap()
    }

    @Test func aSecondPencilMovesTheSelection() throws {
        try tapPencil("Fix login bug")
        #expect(editing == .activity(Fix.items[0].id))
        #expect(try selectedRows() == [Fix.items[0].id])
        try tapPencil("Standup")
        #expect(editing == .activity(Fix.items[1].id))
        #expect(try selectedRows() == [Fix.items[1].id])
    }

    @Test func theTimelineCardHoldsNoEditSection() throws {
        editing = .activity(Fix.items[0].id)
        #expect(try content().inspect().findAll(ActivityEditSection.self).isEmpty)
    }

    @Test func thePanelShowsTheEditSectionForAnActivity() throws {
        let sut = try panel(.activity(Fix.items[0].id)).inspect()
        #expect(sut.findAll(ActivityEditSection.self).count == 1)
        #expect(throws: Never.self) { try sut.find(text: "Edit activity") }
    }

    @Test func thePanelShowsTheAddSectionForASpan() throws {
        let span = DateInterval(start: Fix.at(4, 10, 30), end: Fix.at(4, 11))
        let sut = try panel(.add(span)).inspect()
        #expect(sut.findAll(ActivityEditSection.self).count == 1)
        #expect(throws: Never.self) { try sut.find(text: "Add activity") }
    }

    @Test func thePanelScrollsOnItsOwn() throws {
        let sut = try panel(.activity(Fix.items[0].id)).inspect()
        #expect(throws: Never.self) { try sut.find(ViewType.ScrollView.self).find(ActivityEditSection.self) }
    }

    @Test func aFailedDeleteKeepsTheSectionOpen() throws {
        var actions = ActivityDayActions()
        actions.delete = { _ in false }
        editing = .activity(Fix.items[0].id)
        try tapDelete(panel(.activity(Fix.items[0].id), actions))
        #expect(editing == .activity(Fix.items[0].id))
    }

    @Test func aDeleteThatWorksClosesTheSection() throws {
        var deleted: [ActivityID] = []
        var actions = ActivityDayActions()
        actions.delete = { deleted.append($0); return true }
        editing = .activity(Fix.items[0].id)
        try tapDelete(panel(.activity(Fix.items[0].id), actions))
        #expect(deleted == [Fix.items[0].id])
        #expect(editing == nil)
    }

    @Test func theCloseButtonClosesThePanel() throws {
        editing = .activity(Fix.items[0].id)
        try Find.button(panel(.activity(Fix.items[0].id)).inspect(), label: Copywriter.activitiesClose).tap()
        #expect(editing == nil)
    }

    @Test func thePanelShowsOnlyForATargetInThisDay() {
        let day = Fix.day()
        #expect(ActivityEditPanel.shows(.activity(Fix.items[0].id), in: day))
        #expect(!ActivityEditPanel.shows(.activity(ActivityID()), in: day))
        #expect(ActivityEditPanel.shows(.add(DateInterval(start: Fix.at(4, 10, 30), end: Fix.at(4, 11))), in: day))
        #expect(!ActivityEditPanel.shows(.add(DateInterval(start: Fix.at(5, 10, 30), end: Fix.at(5, 11))), in: day))
    }
}
