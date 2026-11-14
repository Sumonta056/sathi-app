import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar block view")
struct CalendarBlockViewTests {
    private let cal = Calendar.current
    private let start = day(2026, 11, 12, 10, 35)
    private let end = day(2026, 11, 12, 11, 40)

    private func block(_ style: CalendarBlockStyle) -> CalendarBlock {
        CalendarBlock(
            id: "b", title: "Design review", interval: DateInterval(start: start, end: end), style: style,
            source: .event(CalendarEventInfo(id: "b", title: "Design review", start: start, end: end, calendarID: "c")),
            isAllDay: false, activityIDs: []
        )
    }

    private func view(_ style: CalendarBlockStyle, height: CGFloat) throws -> InspectableView<ViewType.ClassifiedView> {
        try CalendarBlockView(block: block(style), height: height, categories: [], calendar: cal).inspect()
    }

    @Test func textNeedsTheMinimumHeight() {
        #expect(!CalendarBlockView.showsText(height: UIMetrics.calendarBlockMinHeight - 1))
        #expect(CalendarBlockView.showsText(height: UIMetrics.calendarBlockMinHeight))
        #expect(!CalendarBlockView.showsTimeRange(height: UIMetrics.calendarTimeRangeMinHeight - 1))
        #expect(CalendarBlockView.showsTimeRange(height: UIMetrics.calendarTimeRangeMinHeight))
    }

    @Test func shortBlockHasNoText() throws {
        let sut = try view(.away, height: UIMetrics.calendarBlockMinHeight - 1)
        #expect(sut.findAll(ViewType.Text.self).isEmpty)
    }

    @Test func tallBlockShowsTitleAndRange() throws {
        let sut = try view(.activity(category: nil), height: UIMetrics.calendarTimeRangeMinHeight)
        #expect(throws: Never.self) { try sut.find(text: "Design review") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.trackerSpan(start, end, calendar: cal)) }
    }

    @Test func middleBlockShowsTitleOnly() throws {
        let sut = try view(.activity(category: nil), height: UIMetrics.calendarBlockMinHeight)
        #expect(throws: Never.self) { try sut.find(text: "Design review") }
        #expect(Find.lacks(sut, text: Copywriter.trackerSpan(start, end, calendar: cal)))
    }

    @Test func eventUsesAnOutlineInItsCalendarColor() {
        let look = CalendarBlockLook.of(.event(colorHex: 0x4285F4), categories: [])
        #expect(look.stroke == Color(hex: 0x4285F4))
        #expect(look.fill == .clear)
        #expect(look.text == Night.text)
    }

    @Test func awayIsGrey() {
        let look = CalendarBlockLook.of(.away, categories: [])
        #expect(look.fill == Color(hex: 0x2A3346))
        #expect(look.stroke == nil)
    }

    @Test func joinedIsGreen() {
        let look = CalendarBlockLook.of(.joined(category: "Work"), categories: [])
        #expect(look.fill == Color(hex: 0x1E4635))
        #expect(look.text == Color(hex: 0xA6EBC7))
    }

    @Test func activityIsFilledInItsCategoryColor() {
        let cats = [ActivityCategory(name: "Work", colorHex: 0x7FB8FF)]
        let look = CalendarBlockLook.of(.activity(category: "Work"), categories: cats)
        #expect(look.fill == Color(hex: 0x7FB8FF).opacity(UIMetrics.calendarActivityTint))
        #expect(look.stroke == nil)
    }
}
