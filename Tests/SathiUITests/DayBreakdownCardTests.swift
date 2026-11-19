import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Day breakdown card")
struct DayBreakdownCardTests {
    private func sofar() -> TodaySoFar {
        TodaySoFar(
            isOn: true,
            hours: DateInterval(start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 18)),
            segments: [],
            logged: 3 * 3600,
            categories: [
                ActivityCategoryTotal(name: "Work", isNamed: true, seconds: 2 * 3600, percent: 67),
                ActivityCategoryTotal(name: "Reading", isNamed: true, seconds: 3600, percent: 33)
            ],
            away: [ActivityCategoryTotal(name: "Walk", isNamed: true, seconds: 20 * 60, percent: 0)]
        )
    }

    private func card() throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(DayBreakdownCard(sofar: sofar(), categories: []), EngineHarness()).inspect()
    }

    @Test func showsTheTitleAndTheSummary() throws {
        let sut = try card()
        #expect(throws: Never.self) { try sut.find(text: "Breakdown") }
        #expect(throws: Never.self) { try sut.find(text: "2 categories · 3h 0m") }
    }

    @Test func hasOneBarForEachCategoryButNoneForAway() throws {
        let sut = try card()
        #expect(sut.findAll(where: { (try? $0.accessibilityIdentifier()) == "day.breakdown.bar" }).count == 2)
    }

    @Test func showsOnlyWithTheTrackerOnAndRows() {
        #expect(TodayLowerRow.showsBreakdown(sofar()))
        #expect(!TodayLowerRow.showsBreakdown(.off))
    }

    @Test func barShareIsTheShareOfTheLoggedTime() {
        #expect(DayBreakdownCard.share(2 * 3600, of: 3 * 3600) == 2.0 / 3.0)
        #expect(DayBreakdownCard.share(60, of: 0) == 0)
    }

    @Test func nowLabelHidesTheHourNumbersItWouldCover() {
        #expect(ActivityAxis.hides(markX: 300, labelX: 300))
        #expect(ActivityAxis.hides(markX: 300 + UIMetrics.todayNowLabelHalfWidth, labelX: 300))
        #expect(!ActivityAxis.hides(markX: 300 + UIMetrics.todayNowLabelHalfWidth + UIMetrics.trackerAxisMarkHalfWidth + 1, labelX: 300))
        #expect(!ActivityAxis.hides(markX: 300, labelX: nil))
    }

    @Test func nowLabelStaysInsideTheAxis() {
        #expect(ActivityAxis.labelX(width: 600, fraction: 0) == UIMetrics.todayNowLabelHalfWidth)
        #expect(ActivityAxis.labelX(width: 600, fraction: 1) == 600 - UIMetrics.todayNowLabelHalfWidth)
        #expect(ActivityAxis.labelX(width: 600, fraction: 0.5) == 300)
    }

    @Test func todaySoFarAxisKnowsWhereNowIs() throws {
        let card = TodaySoFarCard(sofar: sofar(), categories: [], calendar: .current, now: day(2026, 3, 4, 12))
        let axis = try hosted(card, EngineHarness()).inspect().find(ActivityAxis.self).actualView()
        #expect(axis.nowAt != nil)
    }
}
