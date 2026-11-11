import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reports detail")
struct ReportsTests {
    private func detail(_ h: EngineHarness, _ kind: ReportRange = .week, selected: HabitID = .water) -> some View {
        HabitReportsView(range: h.engine.currentRange(kind), selected: selected)
            .environmentObject(h.engine)
    }

    @Test func theWeekDetailShowsTheWaterChartTitle() throws {
        let sut = try detail(EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Water · this week") }
    }

    @Test func theDayDetailShowsTheTodayTitle() throws {
        let texts = try MenuFind.texts(detail(EngineHarness(), .day).inspect())
        #expect(texts.contains("Water · today"))
    }

    @Test func selectingReadingShowsTheReadingChart() throws {
        let sut = try detail(EngineHarness(), selected: .reading).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Reading · this week") }
        #expect(Find.lacks(sut, text: "Water · this week"))
    }

    @Test func theDetailShowsTheStreakCalendarAndTheFacts() throws {
        let sut = try detail(EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(StreakCalendarView.self) }
        #expect(throws: Never.self) { try sut.find(ReportFactsView.self) }
    }

    @Test func theDetailHasNoExportMenu() throws {
        let sut = try detail(EngineHarness()).inspect()
        #expect(sut.findAll(ViewType.Menu.self).isEmpty)
    }
}
