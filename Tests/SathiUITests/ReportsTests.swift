import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reports window")
struct ReportsTests {
    private func reports(_ h: EngineHarness, range: ReportRange = .week, selected: HabitID = .water) -> some View {
        ReportsView(range: range, selected: selected)
            .environmentObject(h.engine)
    }

    private func tile(_ h: EngineHarness, _ habit: HabitID) throws -> ReportTile {
        try #require(h.engine.reportScreen(.week, selected: .water).tiles.first { $0.habit == habit })
    }

    @Test func showsTheHeadlineAndSublineOfTheWeekScreen() throws {
        let h = EngineHarness()
        let screen = h.engine.reportScreen(.week, selected: .water)
        let sut = try ReportsView().environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(text: screen.headline) }
        #expect(throws: Never.self) { try sut.find(text: screen.subline) }
        #expect(throws: Never.self) { try sut.find(text: "Water · this week") }
    }

    @Test func theReportsWindowHasNoExportMenu() throws {
        let sut = try ReportsView().environmentObject(EngineHarness().engine).inspect()
        #expect(throws: (any Error).self) { try sut.find(text: "Export") }
        #expect(sut.findAll(ViewType.Menu.self).isEmpty)
    }

    @Test func rangeSegmentHasThreeRangesAndMarksTheSelectedOne() throws {
        let sut = try RangeSegment(range: Box(ReportRange.week).binding).inspect()
        for name in ["Day", "Week", "Month"] {
            #expect(throws: Never.self) { try Find.button(sut, holding: name) }
        }
        #expect(try A11y.isSelected(Find.button(sut, holding: "Week")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "Day")))
    }

    @Test func tappingDaySelectsTheDayRange() throws {
        let range = Box(ReportRange.week)
        try Find.button(RangeSegment(range: range.binding).inspect(), holding: "Day").tap()
        #expect(range.value == .day)
    }

    @Test func theDayRangeShowsATodayHeadline() throws {
        let h = EngineHarness()
        let headline = h.engine.reportScreen(.day, selected: .water).headline
        #expect(headline.hasPrefix("Today"))
        let texts = try MenuFind.texts(reports(h, range: .day).inspect())
        #expect(texts.contains(headline))
        #expect(texts.contains("Water · today"))
    }

    @Test func showsOneTilePerHabit() throws {
        let sut = try reports(EngineHarness()).inspect()
        #expect(sut.findAll(HabitTileView.self).count == 3)
        for label in ["WATER", "READING", "MEDITATION"] {
            #expect(throws: Never.self) { try sut.find(text: label) }
        }
    }

    @Test func tappingTheReadingTileSelectsReading() throws {
        let h = EngineHarness()
        let selected = Box(HabitID.water)
        let sut = try HabitTileView(tile: tile(h, .reading), selected: selected.binding).inspect()
        try sut.find(ViewType.Button.self).tap()
        #expect(selected.value == .reading)
    }

    @Test func selectingReadingShowsTheReadingChart() throws {
        let sut = try reports(EngineHarness(), selected: .reading).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Reading · this week") }
        #expect(Find.lacks(sut, text: "Water · this week"))
    }

    @Test func anOffHabitTileSaysOffAndIsDisabled() throws {
        let h = EngineHarness()
        let selected = Box(HabitID.water)
        let sut = try HabitTileView(tile: tile(h, .meditation), selected: selected.binding).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Off") }
        #expect(try sut.find(ViewType.Button.self).isDisabled())
        #expect(selected.value == .water)
    }

    @Test func anOnHabitTileIsEnabledAndShowsItsNote() throws {
        let h = EngineHarness()
        let water = try tile(h, .water)
        let sut = try HabitTileView(tile: water, selected: Box(HabitID.water).binding).inspect()
        #expect(try !sut.find(ViewType.Button.self).isDisabled())
        #expect(throws: Never.self) { try sut.find(text: water.note) }
        #expect(Find.lacks(sut, text: "Off"))
    }

    @Test func theOffTileInTheWindowSaysOff() throws {
        let sut = try reports(EngineHarness()).inspect()
        let meditation = try sut.find(text: "MEDITATION").find(HabitTileView.self, relation: .parent)
        #expect(throws: Never.self) { try meditation.find(text: "Off") }
    }
}
