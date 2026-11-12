import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity month view")
struct ActivityMonthViewTests {
    typealias Fix = ActivityViewSupport

    private let month = MonthKey(year: 2026, month: 3)!
    private var days: [ActivityDay] { [Fix.day(4), Fix.day(5, [Fix.item("Docs", "Learning", 5, (9, 0), (10, 0))])] }

    private func view(_ actions: ActivityMonthActions) -> ActivityMonthView {
        ActivityMonthView(month: month, days: days, categories: ActivityCategory.defaults, calendar: Fix.calendar, actions: actions)
    }

    private func press(_ sut: ActivityMonthView, _ title: String) throws {
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: title) != nil }.tap()
    }

    @Test func showsFourTilesAndARowForEachDay() throws {
        let sut = try view(ActivityMonthActions()).inspect()
        for label in ["REAL WORK", "AVERAGE DAY", "BEST DAY", "AWAY"] {
            #expect(throws: Never.self) { try sut.find(text: label) }
        }
        #expect(throws: Never.self) { try sut.find(text: "Wed, 4 Mar") }
        #expect(throws: Never.self) { try sut.find(text: "Thu, 5 Mar") }
    }

    @Test func aRowOpensThatDay() throws {
        var opened: DayKey?
        var actions = ActivityMonthActions()
        actions.openDay = { opened = $0 }
        try press(view(actions), "Thu, 5 Mar")
        #expect(opened == Fix.key(5))
    }

    @Test func copyMonthlyGivesTheMonthlyText() throws {
        var copied: String?
        var actions = ActivityMonthActions()
        actions.copy = { copied = $0 }
        try press(view(actions), "Copy monthly report")
        #expect(copied == ActivityMonthText.make(days, month: month, calendar: Fix.calendar))
    }

    @Test func exportMonthCallsTheClosure() throws {
        var count = 0
        var actions = ActivityMonthActions()
        actions.exportMonth = { count += 1 }
        try press(view(actions), "Export month")
        #expect(count == 1)
    }
}
