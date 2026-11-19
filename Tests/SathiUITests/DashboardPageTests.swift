import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Dashboard page")
struct DashboardPageTests {
    private func page(
        _ kind: ReportRange, range: StatsRange? = nil, selected: HabitID? = nil, _ given: EngineHarness? = nil
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        let h = given ?? ReportsFixture.harness()
        return try hosted(DashboardPage(kind: kind, range: range, selected: selected), h).inspect()
    }

    private func header(_ sut: InspectableView<ViewType.ClassifiedView>) throws -> InspectableView<ViewType.View<DashboardHeader>> {
        try sut.find(DashboardHeader.self)
    }

    private func pastDay() -> StatsRange {
        StatsRange.containing(day(2026, 11, 10, 12), kind: .day, calendar: ReportsFixture.harness().engine.rangeCalendar)
    }

    @Test func dayShowsTheDateTheGreetingAndTheScoreLine() throws {
        let h = ReportsFixture.harness()
        let screen = h.engine.todayScreen
        let top = try header(page(.day, h))
        #expect(throws: Never.self) { try top.find(text: screen.dateLine) }
        #expect(throws: Never.self) { try top.find(text: screen.greeting) }
        #expect(Find.lacks(top, text: "Dashboard"))
        #expect(throws: Never.self) { try top.find(DashboardScoreLine.self).find(text: "1 of 4 goals today · \u{2212}1 vs yesterday") }
    }

    @Test func dayHasTheRangeBarQuickReminderAndBreakButNoExport() throws {
        let top = try header(page(.day))
        #expect(throws: Never.self) { try top.find(RangeBar.self) }
        #expect(throws: Never.self) { try Find.button(top, holding: "Quick reminder") }
        #expect(throws: Never.self) { try top.find(BreakMenu.self) }
        #expect(Find.lacks(top, text: "Export CSV"))
    }

    @Test func theQuickReminderButtonOpensTheAddPopup() throws {
        let h = ReportsFixture.harness()
        try Find.button(header(page(.day, h)), holding: "Quick reminder").tap()
        #expect(h.presenter.calls.last == .showQuickAdd)
    }

    @Test func dayShowsTheTabRowWithAllBuddiesFirst() throws {
        let titles = try MenuFind.texts(page(.day).find(ReportsTabRow.self))
        #expect(titles.first == "All buddies")
        #expect(titles.contains("Shanti · 1/1"))
        #expect(titles.contains("Fota · 0/1"))
    }

    @Test func dayWithNoBuddyOnHidesTheScoreLine() throws {
        let h = EngineHarness(at: ReportsFixture.now) {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
        }
        let sut = try page(.day, h)
        #expect(sut.findAll(DashboardScoreLine.self).isEmpty)
        #expect(!MenuFind.hasText(sut, containing: "goals today"))
    }

    @Test func weekShowsTheTitleDayByDayAndExport() throws {
        let sut = try page(.week, range: ReportsFixture.week())
        let top = try header(sut)
        #expect(throws: Never.self) { try top.find(text: "Dashboard") }
        #expect(throws: Never.self) { try top.find(RangeBar.self) }
        #expect(throws: Never.self) { try Find.button(top, holding: "Export CSV") }
        #expect(Find.lacks(top, text: "Quick reminder"))
        #expect(sut.findAll(DashboardScoreLine.self).isEmpty)
        #expect(throws: Never.self) { try sut.find(ReportsAllTab.self) }
        #expect(throws: Never.self) { try sut.find(text: "Day by day") }
    }

    @Test func weekKeepsTheDateEyebrow() throws {
        let h = ReportsFixture.harness()
        let top = try header(page(.week, range: ReportsFixture.week(), h))
        #expect(throws: Never.self) { try top.find(text: h.engine.todayScreen.dateLine) }
    }

    @Test func aPastDayShowsTheAllBuddiesReportWithExport() throws {
        let sut = try page(.day, range: pastDay())
        let top = try header(sut)
        #expect(throws: Never.self) { try top.find(text: "Dashboard") }
        #expect(throws: Never.self) { try Find.button(top, holding: "Export CSV") }
        #expect(Find.lacks(top, text: "Quick reminder"))
        #expect(sut.findAll(DashboardScoreLine.self).isEmpty)
        #expect(throws: Never.self) { try sut.find(ReportsAllTab.self) }
    }

    @Test func aBuddyTabShowsItsChartFactsAndMonth() throws {
        let sut = try page(.week, range: ReportsFixture.week(), selected: .gym)
        #expect(throws: (any Error).self) { try sut.find(ReportsAllTab.self) }
        let texts = MenuFind.texts(sut)
        for text in ["Shokti · gym minutes", "daily goal 10 min", "Goal days", "1 of 7", "Shokti · November"] {
            #expect(texts.contains(text))
        }
        #expect(throws: Never.self) { try sut.find(BuddyMonthView.self) }
    }

    @Test func aBuddyTabOnDayShowsTheBuddyAndNoScoreLine() throws {
        let sut = try page(.day, selected: .meditation)
        #expect(throws: Never.self) { try sut.find(ReportsBuddyTab.self) }
        #expect(throws: (any Error).self) { try sut.find(ReportsAllTab.self) }
        #expect(sut.findAll(DashboardScoreLine.self).isEmpty)
        #expect(try Find.button(sut, holding: "Shanti · 1/1").accessibilityTraits().contains(.isSelected))
    }
}
