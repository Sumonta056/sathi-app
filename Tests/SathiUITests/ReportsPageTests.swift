import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reports page")
struct ReportsPageTests {
    private func harness() -> EngineHarness {
        EngineHarness(at: day(2026, 3, 4, 20)) {
            $0.events = [
                .done(.water, 8, at: day(2026, 3, 2, 12)),
                .done(.water, 8, at: day(2026, 3, 3, 12)),
                .done(.reading, 140, at: day(2026, 3, 3, 14)),
                .done(.water, 6, at: day(2026, 2, 24, 12))
            ]
        }
    }

    private func page(_ h: EngineHarness, selected: HabitID? = nil) throws -> InspectableView<ViewType.ClassifiedView> {
        try ReportsPage(selected: selected).environmentObject(h.engine).inspect()
    }

    @Test func showsTheTitleAndTheRangeBar() throws {
        let sut = try page(harness())
        #expect(throws: Never.self) { try sut.find(text: "Reports") }
        let range = StatsRange.containing(day(2026, 3, 4, 20), kind: .week, calendar: .current)
        let title = Copywriter.rangeTitle(range, now: day(2026, 3, 4, 20), calendar: .current)
        #expect(throws: Never.self) { try sut.find(text: title) }
    }

    @Test func showsOneCardPerBuddyWithTotalAndGoalDays() throws {
        let sut = try page(harness())
        #expect(sut.findAll(BuddyTotalCard.self).count == 4)
        let texts = MenuFind.texts(sut)
        for label in ["Fota · water", "Boi · reading", "Shanti · meditation", "Shokti · gym"] {
            #expect(texts.contains(label))
        }
        #expect(texts.contains("16 glasses"))
        #expect(texts.contains("2h 20m"))
        #expect(MenuFind.hasText(sut, containing: "goal met"))
        #expect(MenuFind.hasText(sut, containing: " days"))
    }

    @Test func theChangeLineComparesWithLastWeek() throws {
        let texts = try MenuFind.texts(page(harness()))
        #expect(texts.contains("+10 glasses vs last week"))
    }

    @Test func anOffBuddyIsDimmedAndSaysOff() throws {
        let sut = try page(harness())
        let card = try sut.find(text: "Shanti · meditation").find(BuddyTotalCard.self, relation: .parent)
        #expect(throws: Never.self) { try card.find(text: "Off") }
        #expect(try card.find(ViewType.Button.self).opacity() < 1)
    }

    @Test func noDetailChartUntilACardIsTapped() throws {
        #expect(throws: (any Error).self) { try page(harness()).find(HabitReportsView.self) }
    }

    @Test func tappingACardShowsItsDetailChart() throws {
        let sut = try page(harness(), selected: .reading)
        #expect(throws: Never.self) { try sut.find(HabitReportsView.self) }
        #expect(throws: Never.self) { try sut.find(text: "Reading · this week") }
    }

    @Test func tappingTheCardSelectsItAndTappingAgainHidesTheDetail() throws {
        let selected = Box<HabitID?>(nil)
        let sut = try BuddyTotalsRow(
            totals: harness().engine.buddyRange(StatsRange.containing(day(2026, 3, 4), kind: .week, calendar: .current)).totals,
            kind: .week,
            selected: selected.binding
        ).inspect()
        try Find.button(sut, holding: "Boi · reading").tap()
        #expect(selected.value == .reading)
        try Find.button(sut, holding: "Boi · reading").tap()
        #expect(selected.value == nil)
    }

    @Test func theGoalDaysChartAndTheCategoryCardAreShown() throws {
        let sut = try page(harness())
        #expect(throws: Never.self) { try sut.find(text: "Goals met per day of 2 buddies") }
        #expect(throws: Never.self) { try sut.find(text: "Time by category vs last week") }
        #expect(throws: Never.self) { try sut.find(text: "No activities in this range.") }
    }

    @Test func categoryRowsShowTimeAndChangeWithCalendarEventsAndAway() throws {
        let h = EngineHarness.tracker(
            at: day(2026, 3, 4, 20),
            activities: [
                Activity(text: "Fix bug", category: "Coding", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 11)),
                Activity(text: "Fix bug", category: "Coding", start: day(2026, 2, 25, 9), end: day(2026, 2, 25, 10)),
                Activity(kind: .event, text: "Standup", start: day(2026, 3, 4, 12), end: day(2026, 3, 4, 13))
            ]
        )
        let sut = try ReportsPage().environmentObject(h.engine).inspect()
        let texts = MenuFind.texts(sut)
        #expect(texts.contains("Coding"))
        #expect(texts.contains("+1 h"))
        #expect(texts.contains("Calendar events"))
    }

    @Test func exportButtonIsPresent() throws {
        let sut = try page(harness())
        #expect(throws: Never.self) { try Find.button(sut, holding: "Export CSV") }
        #expect(sut.findAll(ReportsExportButton.self).count == 1)
    }
}
