import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reports parts")
struct ReportsPartsTests {
    private func harness() -> EngineHarness {
        EngineHarness {
            $0.events = [1, 2, 3].map { .done(.water, 8, at: day(2026, 3, $0, 12)) } + [.snooze(.water, at: day(2026, 3, 3, 11))]
        }
    }

    @Test func streakCalendarShowsTitleStreakAndWeekdayHeaders() throws {
        let month = harness().engine.reportScreen(.week, selected: .water).calendar
        let sut = try StreakCalendarView(month: month).inspect()
        #expect(throws: Never.self) { try sut.find(text: "March streak") }
        #expect(throws: Never.self) { try sut.find(text: "3 days") }
        let headers = MenuFind.texts(sut).filter { ["M", "T", "W", "F", "S"].contains($0) }
        #expect(headers == ["M", "T", "W", "T", "F", "S", "S"])
    }

    @Test func factsShowEachLabelAndValue() throws {
        let facts = harness().engine.reportScreen(.week, selected: .water).facts
        #expect(facts.map(\.label) == ["Best day", "Snoozes this week", "Longest streak"])
        let texts = try MenuFind.texts(ReportFactsView(facts: facts).inspect())
        for fact in facts {
            #expect(texts.contains(fact.label))
            #expect(texts.contains(fact.value))
        }
    }
}
