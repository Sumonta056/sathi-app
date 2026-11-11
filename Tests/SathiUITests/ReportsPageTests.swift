import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reports page")
struct ReportsPageTests {
    private func page(_ given: EngineHarness? = nil, selected: HabitID? = nil) throws
        -> InspectableView<ViewType.ClassifiedView> {
        let h = given ?? ReportsFixture.harness()
        return try ReportsPage(range: ReportsFixture.week(), selected: selected).environmentObject(h.engine).inspect()
    }

    @Test func showsTheTitleTheRangeBarAndExport() throws {
        let sut = try page()
        #expect(throws: Never.self) { try sut.find(text: "Reports") }
        #expect(throws: Never.self) { try Find.button(sut, holding: "Export CSV") }
    }

    @Test func theTabRowHasAllBuddiesThenOneTabPerBuddyWithGoalDays() throws {
        let sut = try page()
        let row = try sut.find(ReportsTabRow.self)
        let titles = MenuFind.texts(row)
        #expect(titles == ["All buddies", "Fota · 2/7", "Boi · 1/7", "Shanti · 3/7", "Shokti · 1/7"])
    }

    @Test func allBuddiesIsSelectedByDefault() throws {
        let sut = try page()
        #expect(throws: Never.self) { try sut.find(ReportsAllTab.self) }
        #expect(throws: (any Error).self) { try sut.find(ReportsBuddyTab.self) }
        #expect(try Find.button(sut, holding: "All buddies").accessibilityTraits().contains(.isSelected))
    }

    @Test func tappingABuddyTabSelectsItAndAllBuddiesGoesBack() throws {
        let selected = Box<HabitID?>(nil)
        let scores = ReportsFixture.harness().engine.reportsOverview(ReportsFixture.week()).scores
        let sut = try ReportsTabRow(scores: scores, selected: selected.binding).inspect()
        try Find.button(sut, holding: "Boi · 1/7").tap()
        #expect(selected.value == .reading)
        try Find.button(sut, holding: "All buddies").tap()
        #expect(selected.value == nil)
    }

    @Test func anOffBuddyTabIsDisabled() throws {
        let sut = try page(EngineHarness(at: ReportsFixture.now))
        #expect(try Find.button(sut, holding: "Shanti · 0/7").isDisabled())
        #expect(try !Find.button(sut, holding: "Fota · 0/7").isDisabled())
    }

    @Test func theScoreCardShowsGoalsHeadlineAndChange() throws {
        let texts = try MenuFind.texts(page().find(ReportsScoreCard.self))
        for text in [
            "7",
            "of 28 goals",
            "WEEK SCORE · 3 DAYS SO FAR",
            "Good week. Shanti leads, Shokti needs a push.",
            "+6 goals vs the same days last week · streak 0 days",
            "2/7",
            "Fota"
        ] {
            #expect(texts.contains(text))
        }
    }

    @Test func theDayGridShowsDaysValuesAndLegend() throws {
        let texts = try MenuFind.texts(page().find(DayByDayCard.self))
        for text in ["Day by day", "Mon 9", "Wed 11", "8", "3", "15m", Copywriter.reportsDayByDayLegend] {
            #expect(texts.contains(text))
        }
    }

    @Test func aBuddyNameInTheGridOpensItsTab() throws {
        let opened = Box<HabitID?>(nil)
        let overview = ReportsFixture.harness().engine.reportsOverview(ReportsFixture.week())
        let sut = try DayByDayCard(overview: overview) { opened.value = $0 }.inspect()
        try Find.button(sut, holding: "Shokti").tap()
        #expect(opened.value == .gym)
    }

    @Test func theBottomRowHasTheCategoryCardAndTheStreakCalendar() throws {
        let sut = try page()
        #expect(throws: Never.self) { try sut.find(text: "Time by category") }
        #expect(throws: Never.self) { try sut.find(text: "No activities in this range.") }
        #expect(throws: Never.self) { try sut.find(StreakOverviewView.self) }
        #expect(throws: Never.self) { try sut.find(text: "November 2026") }
    }

    @Test func aBuddyTabShowsItsChartFactsAndMonth() throws {
        let sut = try page(selected: .gym)
        #expect(throws: (any Error).self) { try sut.find(ReportsAllTab.self) }
        let texts = MenuFind.texts(sut)
        for text in [
            "Shokti · gym minutes",
            "daily goal 10 min",
            "THIS WEEK",
            "10m",
            "Goal days",
            "1 of 7",
            "Mon · 10m",
            "Shokti · November",
            "1 goal day"
        ] {
            #expect(texts.contains(text))
        }
        #expect(throws: Never.self) { try sut.find(BuddyMonthView.self) }
    }

    @Test func theCalendarMonthFollowsTheRange() {
        let calendar = Calendar.current
        let past = StatsRange.containing(day(2026, 10, 20), kind: .week, calendar: calendar)
        let month = ReportsAllTab.month(past, now: ReportsFixture.now, calendar: calendar)
        #expect(month.holds(day(2026, 10, 20)))
        let current = ReportsAllTab.month(ReportsFixture.week(), now: ReportsFixture.now, calendar: calendar)
        #expect(current.holds(ReportsFixture.now))
    }

    @Test func anOffBuddySelectionShowsAllBuddies() throws {
        let sut = try page(EngineHarness(at: ReportsFixture.now), selected: .gym)
        #expect(throws: Never.self) { try sut.find(ReportsAllTab.self) }
        #expect(throws: (any Error).self) { try sut.find(ReportsBuddyTab.self) }
    }

    @Test func theTabRowScrollsSidewaysWhenTheWindowIsNarrow() throws {
        let row = try page().find(ReportsTabRow.self)
        #expect(throws: Never.self) { try row.find(ViewType.ScrollView.self) }
    }
}
