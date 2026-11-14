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

    @Test func nextStaysEnabledOnTheRangeThatHoldsNow() throws {
        for kind in ReportRange.allCases {
            let sut = try header(box(kind))
            #expect(try !Find.button(sut, label: "Next").isDisabled())
        }
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

    @Test func showsTheSixAMNote() throws {
        #expect(throws: Never.self) { try header(box(.week)).find(text: "6 AM to 6 AM") }
    }
}
