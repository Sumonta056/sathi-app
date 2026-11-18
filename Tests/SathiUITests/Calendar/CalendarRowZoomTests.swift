import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar row zoom")
struct CalendarRowZoomTests {
    private func page(_ h: EngineHarness, _ kind: ReportRange) throws -> InspectableView<ViewType.ClassifiedView> {
        let range = CalendarPageRange.containing(day(2026, 3, 4, 12), kind: kind, calendar: h.engine.rangeCalendar)
        return try CalendarPage(range: range).environmentObject(h.engine).inspect()
    }

    @Test func dayAndWeekShowTheRowControl() throws {
        for kind in [ReportRange.day, .week] {
            let sut = try page(EngineHarness(at: day(2026, 3, 4, 12)), kind)
            for text in ["Row", "1 h", "30 min", "15 min"] {
                #expect(throws: Never.self) { try sut.find(text: text) }
            }
        }
    }

    @Test func monthHasNoRowControl() throws {
        let sut = try page(EngineHarness(at: day(2026, 3, 4, 12)), .month)
        #expect(Find.lacks(sut, text: "Row"))
        #expect(Find.lacks(sut, text: "15 min"))
    }

    @Test func theControlSavesTheStep() throws {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        try Find.button(page(h, .week), holding: "15 min").tap()
        #expect(h.engine.data.prefs.calendarPage.rowMinutes == 15)
        try Find.button(page(h, .day), holding: "30 min").tap()
        #expect(h.engine.data.prefs.calendarPage.rowMinutes == 30)
    }

    @Test func theGridUsesTheSavedStep() throws {
        let h = EngineHarness(at: day(2026, 3, 4, 12)) { $0.prefs.calendarPage.rowMinutes = 15 }
        let grid = try page(h, .day).find(CalendarSplitGrid.self).actualView()
        #expect(grid.data.grid?.rows.count == 96)
        #expect(grid.data.grid?.rows.first?.endMinute == 15)
    }
}
