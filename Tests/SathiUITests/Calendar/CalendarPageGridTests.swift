import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar page grid")
struct CalendarPageGridTests {
    private func harness() -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        h.calendarWriter.eventsValue = [
            CalendarEventInfo(id: "s", title: "Standup", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 10), calendarID: "work"),
            CalendarEventInfo(id: "h", title: "Holiday", start: day(2026, 3, 4), end: day(2026, 3, 5), calendarID: "work", isAllDay: true)
        ]
        return h
    }

    private func page(_ kind: ReportRange, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        let range = CalendarPageRange.containing(day(2026, 3, 4, 12), kind: kind, calendar: h.engine.rangeCalendar)
        return try CalendarPage(range: range).environmentObject(h.engine).inspect()
    }

    @Test func weekShowsTimedAndAllDayEvents() throws {
        let sut = try page(.week, harness())
        #expect(throws: Never.self) { try sut.find(text: "Standup") }
        #expect(throws: Never.self) { try sut.find(text: "Holiday") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.calendarAllDay) }
        #expect(throws: Never.self) { try sut.find(text: "Midday") }
    }

    @Test func nowLineOnlyInTodaysColumn() throws {
        let sut = try page(.week, harness())
        #expect(sut.findAll(where: { (try? $0.accessibilityIdentifier()) == "calendar.now" }).count == 1)
    }

    @Test func monthShowsTheMonthGrid() throws {
        let sut = try page(.month, harness())
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "calendar.month.today") }
    }
}
