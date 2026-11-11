@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reports parts")
struct ReportsPartsTests {
    @Test func factsShowEachLabelAndValue() throws {
        let facts = ReportsFixture.harness().engine.buddyTab(ReportsFixture.week(), habit: .water).facts
        #expect(facts.map(\.label) == ["Goal days", "Best day", "Daily average", "Streak"])
        let texts = try MenuFind.texts(ReportFactsView(facts: facts).inspect())
        for fact in facts {
            #expect(texts.contains(fact.label))
            #expect(texts.contains(fact.value))
        }
    }

    @Test func barValuesShowTheAmountAndACheckWhenTheGoalIsMet() {
        let bar = ReportBar(id: 0, label: "Mon", value: 12, metGoal: true)
        #expect(ReportChartView.valueText(bar, habit: .gym, hasGoal: true) == "12m \u{2713}")
        #expect(ReportChartView.valueText(bar, habit: .gym, hasGoal: false) == "12m")
    }
}
