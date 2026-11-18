import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar overlap views")
struct CalendarOverlapViewTests {
    private let cal = Calendar.current
    private let start = day(2026, 11, 12, 10, 35)
    private let end = day(2026, 11, 12, 11, 40)

    private func block(_ style: CalendarBlockStyle = .event(colorHex: 0x4285F4), copies: Int = 1) -> CalendarBlock {
        CalendarBlock(
            id: "b", title: "Design review", interval: DateInterval(start: start, end: end), style: style,
            source: .event(CalendarEventInfo(id: "b", title: "Design review", start: start, end: end, calendarID: "c")),
            isAllDay: false, activityIDs: [], copies: copies
        )
    }

    private var text: CalendarBlockText {
        CalendarBlockText(
            time: Copywriter.trackerSpan(start, end, calendar: cal),
            spoken: Copywriter.calendarBlockSpoken("Design review", start, end, calendar: cal)
        )
    }

    private func blockView(copies: Int) throws -> InspectableView<ViewType.ClassifiedView> {
        let math = CalendarGridMath(day: DayKey(start, calendar: cal), calendar: cal, hourHeight: UIMetrics.calendarHourHeight)
        let placed = CalendarPlacedBlock(block: block(copies: copies), lane: 0, lanes: 1)
        return try CalendarEventCard(placed: placed, math: math, context: CalendarBlockContext(texts: ["b": text])).inspect()
    }

    private func labels(_ sut: InspectableView<ViewType.ClassifiedView>) -> [String] {
        sut.findAll(where: { (try? $0.accessibilityLabel().string()) != nil }).compactMap { try? $0.accessibilityLabel().string() }
    }

    @Test func twoCopiesShowTheBadge() throws {
        let sut = try blockView(copies: 2)
        #expect(throws: Never.self) { try sut.find(text: Copywriter.calendarCopies(2)) }
    }

    @Test func oneCopyShowsNoBadge() throws {
        let sut = try blockView(copies: 1)
        #expect(Find.lacks(sut, text: Copywriter.calendarCopies(1)))
        #expect(Find.lacks(sut, text: Copywriter.calendarCopies(2)))
    }

    @Test func twoCopiesAreSpoken() throws {
        let sut = try blockView(copies: 2)
        let spoken = labels(sut)
        #expect(spoken.contains { $0.contains(text.spoken) && $0.contains(Copywriter.calendarCopiesSpoken(2)) })
    }

    @Test func oneCopyIsNotSpokenAsCopies() throws {
        let sut = try blockView(copies: 1)
        #expect(!labels(sut).contains { $0.contains(Copywriter.calendarCopiesSpoken(1)) })
        #expect(labels(sut).contains(text.spoken))
    }

    @Test func backdropLabelOpensTheAwayPanel() throws {
        var opened = 0
        let sut = CalendarAwayBackdrop(block: block(.away), text: text, height: UIMetrics.calendarTimeRangeMinHeight) { opened += 1 }
        let label = try sut.inspect().find(viewWithAccessibilityIdentifier: "calendar.awayBackdrop.label")
        try label.button().tap()
        #expect(opened == 1)
    }

    @Test func stripesLayerHasNoLabel() throws {
        let sut = CalendarAwayBackdrop(block: block(.away), text: text, height: UIMetrics.calendarTimeRangeMinHeight, layer: .stripes) {}
        #expect(throws: (any Error).self) { try sut.inspect().find(viewWithAccessibilityIdentifier: "calendar.awayBackdrop.label") }
    }

    @Test func labelLayerOpensTheAwayPanel() throws {
        var opened = 0
        let sut = CalendarAwayBackdrop(block: block(.away), text: text, height: UIMetrics.calendarTimeRangeMinHeight, layer: .label) { opened += 1 }
        try sut.inspect().find(viewWithAccessibilityIdentifier: "calendar.awayBackdrop.label").button().tap()
        #expect(opened == 1)
    }
}
