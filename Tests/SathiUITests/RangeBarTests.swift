import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Range bar")
struct RangeBarTests {
    private let now = day(2026, 3, 4, 10)
    private var calendar: Calendar { Calendar.current }

    private func bar(_ range: Box<StatsRange>) -> RangeBar {
        RangeBar(range: range.binding, now: now, calendar: calendar)
    }

    private func range(_ kind: ReportRange, at date: Date? = nil) -> Box<StatsRange> {
        Box(StatsRange.containing(date ?? now, kind: kind, calendar: calendar))
    }

    @Test func showsTheSegmentsAndTheWeekTitle() throws {
        let sut = try bar(range(.week)).inspect()
        for name in ["Day", "Week", "Month"] {
            #expect(throws: Never.self) { try Find.button(sut, holding: name) }
        }
        let title = Copywriter.rangeTitle(range(.week).value, now: now, calendar: calendar)
        #expect(throws: Never.self) { try sut.find(text: title) }
        #expect(try A11y.isSelected(Find.button(sut, holding: "Week")))
    }

    @Test func dayAndMonthTitles() throws {
        #expect(throws: Never.self) { try bar(range(.day)).inspect().find(text: "Today, 4 Mar") }
        #expect(throws: Never.self) { try bar(range(.month)).inspect().find(text: "March 2026") }
    }

    @Test func labelsAndTitleStayOnOneLine() throws {
        let sut = try bar(range(.month)).inspect()
        for name in ["Day", "Week", "Month", "March 2026"] {
            #expect(try sut.find(text: name).lineLimit() == 1)
        }
    }

    @Test func forwardIsDisabledOnTheRangeThatHoldsToday() throws {
        let sut = try bar(range(.week)).inspect()
        #expect(try Find.button(sut, label: "Next").isDisabled())
        #expect(try !Find.button(sut, label: "Previous").isDisabled())
    }

    @Test func forwardIsEnabledOnAnOlderRange() throws {
        let old = range(.week, at: day(2026, 2, 25, 10))
        #expect(try !Find.button(bar(old).inspect(), label: "Next").isDisabled())
    }

    @Test func backMovesToThePreviousRange() throws {
        let shown = range(.week)
        let expected = shown.value.previous
        try Find.button(bar(shown).inspect(), label: "Previous").tap()
        #expect(shown.value == expected)
    }

    @Test func forwardMovesToTheNextRange() throws {
        let shown = range(.week, at: day(2026, 2, 25, 10))
        let expected = shown.value.next
        try Find.button(bar(shown).inspect(), label: "Next").tap()
        #expect(shown.value == expected)
    }

    @Test func changingTheKindKeepsTheFirstDayOfAnOldRange() throws {
        let shown = range(.week, at: day(2026, 2, 25, 10))
        try Find.button(bar(shown).inspect(), holding: "Month").tap()
        #expect(shown.value.kind == .month)
        #expect(shown.value.holds(shown.value.interval.start))
        #expect(shown.value.interval.start == day(2026, 2, 1))
    }

    @Test func changingTheKindOnTheCurrentRangeKeepsToday() throws {
        let shown = range(.week)
        try Find.button(bar(shown).inspect(), holding: "Day").tap()
        #expect(shown.value == StatsRange.containing(now, kind: .day, calendar: calendar))
    }
}
