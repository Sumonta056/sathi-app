import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar page header")
struct CalendarPageHeaderTests {
    private final class Box {
        var range: CalendarPageRange
        init(_ range: CalendarPageRange) { self.range = range }
        var binding: Binding<CalendarPageRange> { Binding(get: { self.range }, set: { self.range = $0 }) }
    }

    private let now = day(2026, 11, 12, 10)
    private var cal: Calendar { Calendar.current }

    private func box(_ kind: ReportRange, at date: Date? = nil) -> Box {
        Box(.containing(date ?? now, kind: kind, calendar: cal))
    }

    private func header(_ box: Box) throws -> InspectableView<ViewType.ClassifiedView> {
        try CalendarPageHeader(range: box.binding, now: now, calendar: cal).inspect()
    }

    @Test func showsTheThreeSegmentButtons() throws {
        let sut = try header(box(.week))
        for name in ["Day", "Week", "Month"] {
            #expect(throws: Never.self) { try Find.button(sut, holding: name) }
        }
    }

    @Test func segmentChangesTheKind() throws {
        let b = box(.week)
        try Find.button(header(b), holding: "Month").tap()
        #expect(b.range.kind == .month)
        try Find.button(header(b), holding: "Day").tap()
        #expect(b.range.kind == .day)
    }

    @Test func monthTitleShowsMonthAndYear() throws {
        let sut = try header(box(.month))
        #expect(throws: Never.self) { try sut.find(text: "November") }
        #expect(throws: Never.self) { try sut.find(text: "2026") }
    }

    @Test func nextAndPreviousMoveTheRange() throws {
        let b = box(.month)
        try Find.button(header(b), label: "Next").tap()
        #expect(b.range == box(.month, at: day(2026, 12, 12, 10)).range)
        try Find.button(header(b), label: "Previous").tap()
        try Find.button(header(b), label: "Previous").tap()
        #expect(b.range == box(.month, at: day(2026, 10, 12, 10)).range)
    }

    @Test func nextHasNoFutureLimitFromAFarFutureRange() throws {
        let b = box(.week, at: day(2030, 1, 10, 10))
        try Find.button(header(b), label: "Next").tap()
        #expect(b.range == box(.week, at: day(2030, 1, 17, 10)).range)
    }

    @Test func todayResetsToTheRangeHoldingNow() throws {
        let b = box(.week, at: day(2026, 9, 2, 10))
        try Find.button(header(b), holding: "Today").tap()
        #expect(b.range == box(.week).range)
    }

    @Test func todayAtOneThirtyKeepsThePreviousPageDay() throws {
        let early = day(2026, 11, 12, 1, 30)
        let b = Box(.containing(day(2026, 9, 2, 10), kind: .day, calendar: cal))
        try CalendarPageHeader(range: b.binding, now: early, calendar: cal).inspect().find(text: "Today")
            .find(ViewType.Button.self, relation: .parent).tap()
        #expect(b.range == .containing(early, kind: .day, calendar: cal))
        #expect(b.range.days == [DayKey(day(2026, 11, 11), calendar: cal)])
    }

    @Test func showsTheSummaryForEveryView() throws {
        let stats = CalendarPageStats(tracked: 42 * 3600 + 5 * 60, planned: 29 * 3600 + 16 * 60)
        for kind in ReportRange.allCases {
            let sut = try CalendarPageHeader(range: box(kind).binding, now: now, calendar: cal, stats: stats).inspect()
            #expect(throws: Never.self) { try sut.find(text: "Tracked 42 h 05 m · Planned 29 h 16 m") }
        }
    }

    @Test func noStatsShowsNoSummary() {
        #expect((try? header(box(.week)).find(CalendarHeaderSummary.self)) == nil)
    }

    @Test func sidePanelButtonNamesTheActionAndTaps() throws {
        var taps = 0
        let shown = try CalendarPageHeader(range: box(.week).binding, now: now, calendar: cal, sidePanelShown: true) { taps += 1 }.inspect()
        try Find.button(shown, label: "Hide side panel").tap()
        let hidden = try CalendarPageHeader(range: box(.week).binding, now: now, calendar: cal, sidePanelShown: false) { taps += 1 }.inspect()
        try Find.button(hidden, label: "Show side panel").tap()
        #expect(taps == 2)
    }

    @Test func headerRowsKeepTheSummaryNextToTheTitleWhenNarrow() {
        #expect(CalendarHeaderLayout.rows([200, 250, 300], width: 800, gap: 10) == [[0, 1, 2]])
        #expect(CalendarHeaderLayout.rows([200, 250, 300], width: 700, gap: 10) == [[0, 1], [2]])
        #expect(CalendarHeaderLayout.rows([200, 250, 300], width: 400, gap: 10) == [[0], [1], [2]])
        #expect(CalendarHeaderLayout.rows([200, 300], width: 400, gap: 10) == [[0], [1]])
    }

    @Test(arguments: [UIMetrics.mainWindowSize.width - UIMetrics.mainSidebarWidth - 40, 1100, 1400])
    func weekHeaderUsesTheSameRowsAsDayAtTheSameWidth(_ width: CGFloat) {
        #expect(height(.week, width: width) == height(.day, width: width))
    }

    private func height(_ kind: ReportRange, width: CGFloat) -> CGFloat {
        let stats = CalendarPageStats(tracked: 21 * 3600 + 5 * 60, planned: 6 * 3600 + 40 * 60)
        let header = CalendarPageHeader(
            range: box(kind).binding, now: now, calendar: cal, stats: stats,
            rowMinutes: .constant(60), weekDays: 7
        )
        return NSHostingController(rootView: header).sizeThatFits(in: CGSize(width: width, height: 0)).height
    }

    @Test(arguments: [ReportRange.day, .week, .month])
    func hasNoSixAMNote(_ kind: ReportRange) throws {
        let sut = try header(box(kind))
        #expect(throws: (any Error).self) { try sut.find(text: "6 AM to 6 AM") }
    }
}
