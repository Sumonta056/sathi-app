import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity day view")
struct ActivityDayViewTests {
    typealias Fix = ActivityViewSupport

    private func view(
        _ actions: ActivityDayActions = ActivityDayActions(), day: ActivityDay = Fix.day(), editing: ActivityEditTarget? = nil
    ) -> ActivityDayView {
        ActivityDayView(
            day: day, overview: ActivityDayOverview(day, loggedChange: .up(48 * 60)), categories: ActivityCategory.defaults,
            calendar: Fix.calendar, calendars: Fix.calendars, actions: actions, editing: editing
        )
    }

    private func press(_ sut: ActivityDayView, _ title: String) throws {
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: title) != nil }.tap()
    }

    @Test func theDayViewHasNoTextCard() throws {
        let sut = try view().inspect()
        #expect(Find.lacks(sut, text: Copywriter.activitiesStandupTitle))
        #expect(Find.lacks(sut, text: Copywriter.activitiesCopy))
    }

    @Test func theTopRowShowsTheTableAndTheFourTiles() throws {
        let sut = try view().inspect()
        #expect(throws: Never.self) { try sut.find(text: "2h 0m") }
        #expect(throws: Never.self) { try sut.find(text: "logged · 2 categories") }
        for label in ["Total logged", "Focus work", "Away", "Activities"] {
            #expect(throws: Never.self) { try sut.find(text: label) }
        }
        #expect(throws: Never.self) { try sut.find(text: "+48m vs yesterday") }
        #expect(throws: Never.self) { try sut.find(text: "100% of the day") }
        #expect(throws: Never.self) { try sut.find(text: "Top: Coding") }
    }

    @Test func aTileWithNoDataShowsADash() throws {
        let sut = try view(day: Fix.day(4, [])).inspect()
        #expect(sut.findAll(ViewType.Text.self) { try $0.string() == "\u{2014}" }.count == 4)
    }

    @Test func theTimelineHeaderCountsActivitiesAndGaps() throws {
        let sut = try view().inspect()
        #expect(throws: Never.self) { try sut.find(text: "Timeline") }
        #expect(throws: Never.self) { try sut.find(text: "2 activities · 2 gaps") }
        #expect(throws: Never.self) { try sut.find(text: "+ Add activity") }
    }

    @Test func everyGapHasAFillButton() throws {
        let sut = try view().inspect()
        #expect(sut.findAll(ActivityGapRow.self).count == 2)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: "Fill this gap") }
    }

    @Test func everyActivityHasAPencilWithItsTitle() throws {
        let sut = try view().inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: "Edit Fix login bug") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: "Edit Standup") }
        #expect(Find.lacks(sut, text: "Edit"))
    }

    @Test func noEditSectionIsOpenAtFirst() throws {
        #expect(try view().inspect().findAll(ActivityEditSection.self).isEmpty)
    }

    @Test func theEditSectionOpensInsideTheTimelineAndOutlinesTheRow() throws {
        let sut = try view(editing: .activity(Fix.items[0].id)).inspect()
        let card = try sut.find(ActivityTimelineCard.self)
        #expect(card.findAll(ActivityEditSection.self).count == 1)
        #expect(throws: Never.self) { try card.find(text: "Edit activity") }
        let rows = try sut.findAll(ActivityTimelineRow.self).map { try $0.actualView() }
        #expect(rows.filter(\.selected).map(\.activity.id) == [Fix.items[0].id])
    }

    @Test func aGapOpensTheAddSectionForThatSpan() throws {
        let gap = DateInterval(start: Fix.at(4, 10, 30), end: Fix.at(4, 11))
        var added: ActivityEdit?
        var actions = ActivityDayActions()
        actions.add = { added = $0; return .saved(ActivityID()) }
        let sut = try view(actions, editing: .add(gap)).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Add activity") }
        try sut.find(ActivityEditSection.self).find(ViewType.Button.self) { try $0.labelView().find(text: "Save") != nil }.tap()
        #expect(added?.start == gap.start)
        #expect(added?.end == gap.end)
    }

    @Test func anEmptyDayShowsTheEmptyLine() throws {
        #expect(throws: Never.self) { try view(day: Fix.day(4, [])).inspect().find(text: "No activities on this day.") }
    }
}
