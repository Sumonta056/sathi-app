import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activities page")
struct ActivitiesPageTests {
    private let now = day(2026, 3, 4, 12)

    private func activities() -> [Activity] {
        [
            Activity(text: "Fix login bug", category: "Coding", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 11)),
            Activity(text: "Docs", category: "Learning", start: day(2026, 3, 2, 9), end: day(2026, 3, 2, 10)),
            Activity(text: "Old work", category: "Coding", start: day(2026, 2, 25, 9), end: day(2026, 2, 25, 10))
        ]
    }

    private func page(
        day: DayKey? = nil, range: ReportRange? = nil, on: Bool = true, items: [Activity]? = nil
    ) throws -> (InspectableView<ViewType.ClassifiedView>, EngineHarness) {
        let list = items ?? activities()
        let h = on ? EngineHarness.tracker(at: now, activities: list) : EngineHarness(
            at: now, activities: InMemoryActivityStore(activities: list)
        )
        let picked = range.map { h.engine.currentRange($0) }
        return try (ActivitiesPage(day: day, range: picked).environmentObject(h.engine).inspect(), h)
    }

    @Test func showsTheTitleAndTheRangeBarOnToday() throws {
        let (sut, _) = try page()
        #expect(throws: Never.self) { try sut.find(text: "Activities") }
        #expect(throws: Never.self) { try sut.find(text: "Today, 4 Mar") }
    }

    @Test func dayShowsTheLogRowsAndTheStandupCopy() throws {
        let (sut, _) = try page()
        #expect(MenuFind.hasText(sut, containing: "Fix login bug"))
        #expect(Find.lacks(sut, text: Copywriter.activitiesStandupTitle))
        #expect(throws: Never.self) { try Find.button(sut, holding: Copywriter.activitiesStandupButton) }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.activitiesAdd) }
    }

    @Test func dayShowsTheCategoryTableTheTilesAndTheTimeline() throws {
        let (sut, _) = try page()
        #expect(throws: Never.self) { try sut.find(text: "logged · 1 category") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.activitiesTileFocus) }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.activitiesTimeline) }
    }

    @Test func weekShowsTheCategoryTableOnTop() throws {
        let (sut, _) = try page(range: .week)
        #expect(sut.findAll(CategoryTableView.self).count == 1)
    }

    @Test func theRouteDayOpensThatDay() throws {
        let (sut, _) = try page(day: DayKey(day(2026, 3, 2, 12), calendar: .current))
        #expect(throws: Never.self) { try sut.find(text: "Mon, 2 Mar") }
        #expect(MenuFind.hasText(sut, containing: "Docs"))
        #expect(!MenuFind.hasText(sut, containing: "Fix login bug"))
    }

    @Test func weekShowsSevenDayRowsAndTheTiles() throws {
        let (sut, _) = try page(range: .week)
        #expect(sut.findAll(ActivityMonthRowView.self).count == 7)
        let texts = MenuFind.texts(sut)
        for label in ["REAL WORK", "AVERAGE DAY", "BEST DAY", "AWAY"] {
            #expect(texts.contains(label))
        }
    }

    @Test func weekTilesShowTheChangeAgainstLastWeek() throws {
        let (sut, _) = try page(range: .week)
        #expect(MenuFind.texts(sut).contains("+2h 0m vs last week"))
    }

    @Test func weekShowsTheCategoryTableAndTheSummaryButton() throws {
        let (sut, _) = try page(range: .week)
        let texts = MenuFind.texts(sut)
        #expect(texts.contains("Coding"))
        #expect(texts.contains("logged · 2 categories"))
        #expect(throws: Never.self) { try Find.button(sut, holding: Copywriter.activitiesSummaryButton) }
        #expect(Find.lacks(sut, text: Copywriter.activitiesStandupButton))
        #expect(Find.lacks(sut, text: Copywriter.activitiesCopy))
    }

    @Test func monthShowsOneRowForEachDay() throws {
        let (sut, _) = try page(range: .month)
        #expect(sut.findAll(ActivityMonthRowView.self).count == 31)
    }

    @Test func aDayRowOpensThatDay() throws {
        var opened: DayKey?
        var actions = ActivityRangeActions()
        actions.openDay = { opened = $0 }
        let h = EngineHarness.tracker(at: now, activities: activities())
        let range = h.engine.currentRange(.week)
        let view = ActivityRangeView(
            range: range, days: h.engine.activityDays(in: range), stats: h.engine.activityRange(range),
            categories: ActivityCategory.defaults, calendar: h.engine.rangeCalendar, now: now, actions: actions
        )
        let sut = try view.inspect()
        let row = try sut.find(ActivityMonthRowView.self) { try $0.actualView().row?.day == DayKey(day(2026, 3, 2, 12), calendar: .current) }
        try row.find(ViewType.Button.self).tap()
        #expect(opened == DayKey(day(2026, 3, 2, 12), calendar: .current))
    }

    @Test func trackerOffWithNoActivitiesSaysSoAndOffersTurnOn() throws {
        let (sut, h) = try page(on: false, items: [])
        #expect(throws: Never.self) { try sut.find(text: Copywriter.activitiesTrackerOff) }
        try Find.button(sut, holding: Copywriter.activitiesTurnOn).tap()
        #expect(h.presenter.calls.last == .showMain(.settings(.tracker)))
    }

    @Test func trackerOffWithActivitiesStillShowsThem() throws {
        let (sut, _) = try page(on: false)
        #expect(MenuFind.hasText(sut, containing: "Fix login bug"))
        #expect(Find.lacks(sut, text: Copywriter.activitiesTrackerOff))
    }

    @Test func exportButtonIsPresent() throws {
        let (sut, _) = try page()
        #expect(throws: Never.self) { try Find.button(sut, holding: Copywriter.activitiesExport) }
        #expect(sut.findAll(ActivitiesExportButton.self).count == 1)
    }

    @Test(arguments: [ReportRange.week, .month])
    func aRangeScrollsWithNoScrollBar(_ range: ReportRange) throws {
        let (sut, _) = try page(range: range)
        let scroll = try sut.find(ActivityRangeView.self).find(ViewType.ScrollView.self)
        #expect(try scroll.showsIndicators() == false)
    }
}
