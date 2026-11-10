import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity day view")
struct ActivityDayViewTests {
    typealias Fix = ActivityViewSupport

    private func view(_ actions: ActivityDayActions = ActivityDayActions(), day: ActivityDay = Fix.day()) -> ActivityDayView {
        ActivityDayView(day: day, categories: ActivityCategory.defaults, calendar: Fix.calendar, actions: actions)
    }

    private func press(_ sut: ActivityDayView, _ title: String) throws {
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: title) != nil }.tap()
    }

    @Test func showsTheFourTiles() throws {
        let sut = try view().inspect()
        for label in ["REAL WORK", "TOP CATEGORY", "ACTIVITIES", "AWAY"] {
            #expect(throws: Never.self) { try sut.find(text: label) }
        }
    }

    @Test func copyAsTextGivesTheStandupText() throws {
        var copied: String?
        var actions = ActivityDayActions()
        actions.copy = { copied = $0 }
        try press(view(actions), "Copy as text")
        #expect(copied == ActivityStandupText.make(Fix.day(), calendar: Fix.calendar))
    }

    @Test func arrowsOpenTheNeighbourDays() throws {
        var picked: [DayKey] = []
        var actions = ActivityDayActions()
        actions.select = { picked.append($0) }
        let sut = view(actions)
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().image().actualImage().name() == "chevron.left" }.tap()
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().image().actualImage().name() == "chevron.right" }.tap()
        #expect(picked == [Fix.key(3), Fix.key(5)])
    }

    @Test func fillAppearsForEveryGapOfAMinuteOrMore() throws {
        let sut = try view().inspect()
        #expect(sut.findAll(ViewType.Button.self) { try $0.labelView().find(text: "Fill") != nil }.count == 2)
    }

    @Test func addPastIsOnTheDay() throws {
        #expect(throws: Never.self) { try view().inspect().find(text: "+ Add past activity") }
    }

    @Test func everyActivityHasAnEditButton() throws {
        let sut = try view().inspect()
        #expect(sut.findAll(ViewType.Button.self) { try $0.labelView().find(text: "Edit") != nil }.count == 2)
    }

    @Test func anEmptyDayShowsTheEmptyLine() throws {
        #expect(throws: Never.self) { try view(day: Fix.day(4, [])).inspect().find(text: "No activities on this day.") }
    }
}
