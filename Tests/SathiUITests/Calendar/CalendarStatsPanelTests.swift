import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar stats panel")
struct CalendarStatsPanelTests {
    private let stats = CalendarPageStats(
        tracked: 2 * 3600 + 5 * 60,
        planned: 40 * 60,
        byCategory: [CalendarCategoryTime(name: "Coding", seconds: 3600 + 35 * 60), CalendarCategoryTime(name: nil, seconds: 30 * 60)],
        away: 15 * 60
    )

    private func panel(_ kind: ReportRange) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(CalendarStatsPanel(stats: stats, kind: kind, categories: ActivityCategory.defaults), EngineHarness()).inspect()
    }

    @Test func dayCardShowsTrackedPlannedAndAway() throws {
        let sut = try panel(.day)
        for line in ["This day", "Tracked", "2 h 05 m", "Planned events", "40 m", "Away", "15 m"] {
            #expect(throws: Never.self) { try sut.find(text: line) }
        }
    }

    @Test func categoriesShowLongestFirst() throws {
        let sut = try panel(.day)
        #expect(throws: Never.self) { try sut.find(text: "By category") }
        let texts = sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }
        let coding = try #require(texts.firstIndex(of: "Coding"))
        let none = try #require(texts.firstIndex(of: Copywriter.trackerNoCategory))
        #expect(coding < none)
        #expect(texts.contains("1 h 35 m"))
        #expect(texts.contains("30 m"))
    }

    @Test func noCategoriesShowsAQuietLine() throws {
        let empty = CalendarStatsPanel(stats: CalendarPageStats(), kind: .week, categories: ActivityCategory.defaults)
        let sut = try hosted(empty, EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "This week") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.calendarNothingTracked) }
    }

    @Test func thePanelHoldsTheShownCalendars() throws {
        #expect(throws: Never.self) { try panel(.month).find(CalendarShownList.self) }
    }

    @Test func theSummaryShowsTrackedAndPlannedInOneLine() throws {
        let summary = try CalendarHeaderSummary(stats: stats).inspect()
        let text = try summary.find(ViewType.Text.self)
        #expect(try text.string() == "Tracked 2 h 05 m · Planned 40 m")
        #expect(try text.lineLimit() == 1)
    }
}
