import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reports calendars and category card")
struct ReportsCalendarTests {
    private let november = StatsRange.containing(day(2026, 11, 11), kind: .month, calendar: .current)

    @Test func theOverviewShowsMonthStreakMondayFirstHeadersAndEveryDay() throws {
        let month = ReportsFixture.harness().engine.streakOverview(november)
        let sut = try StreakOverviewView(month: month).inspect()
        let texts = MenuFind.texts(sut)
        #expect(texts.contains("November 2026"))
        #expect(texts.contains("Streak 0 days"))
        #expect(Array(texts.filter { MonthGrid<EmptyView>.weekdays.contains($0) }.prefix(7)) == MonthGrid<EmptyView>.weekdays)
        #expect(sut.findAll(OverviewDayCell.self).count == 30)
        let ninth = try sut.findAll(OverviewDayCell.self)[8].actualView().day
        #expect(ninth.isStreakDay)
        #expect(texts.contains(Copywriter.reportsStreakLegend))
    }

    @Test func theNextArrowIsOffForTheCurrentMonthAndThePreviousArrowSteps() throws {
        let steps = Box<[Int]>([])
        let month = ReportsFixture.harness().engine.streakOverview(november)
        let sut = try StreakOverviewView(month: month) { steps.value.append($0) }.inspect()
        #expect(try Find.button(sut, label: "Next month").isDisabled())
        try Find.button(sut, label: "Previous month").tap()
        #expect(steps.value == [-1])
    }

    @Test func aPastMonthCanGoForward() throws {
        let month = ReportsFixture.harness().engine.streakOverview(november.previous)
        let sut = try StreakOverviewView(month: month).inspect()
        #expect(try !Find.button(sut, label: "Next month").isDisabled())
        #expect(throws: Never.self) { try sut.find(text: "October 2026") }
    }

    @Test func theBuddyMonthShowsTitleGoalDaysAndEveryDay() throws {
        let month = ReportsFixture.harness().engine.buddyMonth(november, habit: .reading)
        let sut = try BuddyMonthView(month: month).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Boi · November") }
        #expect(throws: Never.self) { try sut.find(text: "1 goal day") }
        #expect(sut.findAll(BuddyMonthCellView.self).count == 30)
    }

    @Test func theCategoryCardListsCategoriesEventsAndAwayWithChange() throws {
        let h = EngineHarness.tracker(
            at: day(2026, 3, 4, 20),
            activities: [
                Activity(text: "Fix bug", category: "Coding", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 11)),
                Activity(text: "Fix bug", category: "Coding", start: day(2026, 2, 25, 9), end: day(2026, 2, 25, 10)),
                Activity(kind: .event, text: "Standup", start: day(2026, 3, 4, 12), end: day(2026, 3, 4, 13)),
                Activity(kind: .away, text: "Lunch", start: day(2026, 3, 4, 13), end: day(2026, 3, 4, 13, 30))
            ]
        )
        let range = h.engine.currentRange(.week)
        let stats = h.engine.activityRange(range)
        let inputs = ReportsCategoryCard.inputs(stats, categories: h.engine.activityCategories)
        #expect(inputs.first { $0.name == Copywriter.trackerAway }?.colorHex == ReportsCategoryColors.away)
        let sut = try ReportsCategoryCard(stats: stats, kind: .week, categories: h.engine.activityCategories).inspect()
        let texts = MenuFind.texts(sut)
        for text in ["Time by category", "Coding", "+1h 0m", "Calendar events", Copywriter.trackerAway] {
            #expect(texts.contains(text))
        }
        #expect(sut.findAll(CategoryTableView.self).count == 1)
    }
}
