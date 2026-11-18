import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar event card")
struct CalendarEventCardTests {
    private let z = FixedZone.berlin

    private var math: CalendarGridMath {
        CalendarGridMath(day: DayKey(z.date(2026, 11, 12), calendar: z.calendar), calendar: z.calendar, hourHeight: UIMetrics.calendarHourHeight)
    }

    private func at(_ h: Int, _ m: Int = 0) -> Date { z.date(2026, 11, 12, h, m) }

    private func event(_ title: String, _ from: Date, _ to: Date, copies: Int = 1) -> CalendarBlock {
        CalendarBlock(
            id: "e-" + title, title: title, interval: DateInterval(start: from, end: to), style: .event(colorHex: 0x4285F4),
            source: .event(CalendarEventInfo(id: "e-" + title, title: title, start: from, end: to, calendarID: "c")),
            isAllDay: false, activityIDs: [], copies: copies
        )
    }

    private func activity(_ title: String, _ from: Date, _ to: Date) -> CalendarBlock {
        let a = Activity(text: title, start: from, end: to)
        return CalendarBlock(
            id: "a-" + title, title: title, interval: DateInterval(start: from, end: to), style: .activity(category: nil),
            source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        )
    }

    private func context(_ blocks: [CalendarBlock]) -> CalendarBlockContext {
        let texts = blocks.map {
            ($0.id, CalendarBlockText(
                time: Fmt.shortRange($0.interval.start, $0.interval.end, calendar: z.calendar),
                spoken: Copywriter.calendarBlockSpoken($0.title, $0.interval.start, $0.interval.end, calendar: z.calendar)
            ))
        }
        return CalendarBlockContext(texts: Dictionary(uniqueKeysWithValues: texts))
    }

    private func card(_ blocks: [CalendarBlock], press: @escaping (CalendarBlock, CGFloat) -> Void = { _, _ in }) throws -> CalendarEventCard {
        let placed = math.place(blocks)
        let host = try #require(placed.first { if case .event = $0.block.source { return true }; return false })
        var ctx = context(blocks)
        ctx.press = press
        return CalendarEventCard(placed: host, math: math, context: ctx)
    }

    @Test func eventHasTheCalendarIconAndTheOutline() throws {
        let sut = try card([event("Standup", at(9), at(10))]).inspect()
        let names = sut.findAll(ViewType.Image.self).compactMap { try? $0.actualImage().name() }
        #expect(names.contains("calendar"))
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "calendar.block.outline") }
    }

    @Test func eventShowsTheShortTimeOnOneLine() throws {
        let sut = try card([event("Standup", at(17), at(18, 30))]).inspect()
        #expect(throws: Never.self) { try sut.find(text: "5:00 – 6:30 PM") }
    }

    @Test func titleWrapsToThreeLinesAtMost() {
        #expect(CalendarBlockFit.titleLines(height: UIMetrics.calendarBlockMinTextHeight) == 1)
        #expect(CalendarBlockFit.titleLines(height: UIMetrics.calendarHourHeight * 4) == UIMetrics.calendarTitleLinesMax)
        #expect(CalendarBlockFit.titleLines(height: 0) == 1)
    }

    @Test func hostListsItsChildrenInsideTheCard() throws {
        let blocks = [event("Planning", at(9), at(10)), activity("Notes", at(9, 5), at(9, 27)), activity("Mail", at(9, 30), at(9, 50))]
        let sut = try card(blocks).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Planning") }
        #expect(throws: Never.self) { try sut.find(text: "Notes") }
        #expect(throws: Never.self) { try sut.find(text: "Mail") }
        #expect(sut.findAll(CalendarActivityBlock.self).count == 2)
    }

    @Test func aClickOnAChildSendsTheChild() throws {
        var pressed: [String] = []
        let blocks = [event("Planning", at(9), at(10)), activity("Notes", at(9, 5), at(9, 27))]
        let sut = try card(blocks) { b, _ in pressed.append(b.id) }.inspect()
        try sut.find(CalendarActivityBlock.self).button().tap()
        #expect(pressed == ["a-Notes"])
    }

    @Test func aClickOnTheCardSendsTheEvent() throws {
        var pressed: [String] = []
        let sut = try card([event("Standup", at(9), at(10))]) { b, _ in pressed.append(b.id) }.inspect()
        try sut.find(viewWithAccessibilityIdentifier: "calendar.event.face").button().tap()
        #expect(pressed == ["e-Standup"])
    }

    @Test func twoCopiesShowTheBadge() throws {
        let sut = try card([event("Standup", at(9), at(10), copies: 2)]).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.calendarCopies(2)) }
    }
}
