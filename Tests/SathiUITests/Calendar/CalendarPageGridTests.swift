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

    @Test func monthGridHidesTheScrollBar() throws {
        let sut = try page(.month, harness())
        let scroll = try sut.find(CalendarMonthGrid.self).find(ViewType.ScrollView.self, relation: .parent)
        #expect(try scroll.showsIndicators() == false)
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

    @Test func dayArgumentOpensThatDay() throws {
        let h = harness()
        let thu = DayKey(day(2026, 3, 5), calendar: h.engine.rangeCalendar)
        let sut = try CalendarPage(day: thu).environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Thu 5 Mar") }
    }

    @Test func monthShowsTheMonthGrid() throws {
        let sut = try page(.month, harness())
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "calendar.month.today") }
    }

    private func tracked() -> EngineHarness {
        let rows = [
            Activity(text: "Notes", category: "Coding", start: day(2026, 3, 4, 9, 5), end: day(2026, 3, 4, 9, 30)),
            Activity(text: "Build", category: "Coding", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 11)),
            Activity(text: "Short", category: "Coding", start: day(2026, 3, 4, 11), end: day(2026, 3, 4, 11, 8)),
            Activity(kind: .away, text: "Away", start: day(2026, 3, 4, 13), end: day(2026, 3, 4, 13, 30))
        ]
        let h = EngineHarness(at: day(2026, 3, 4, 12), activities: InMemoryActivityStore(activities: rows)) { $0.prefs.tracker.isOn = true }
        h.calendarWriter.eventsValue = [
            CalendarEventInfo(id: "s", title: "Standup", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 10), calendarID: "work")
        ]
        return h
    }

    private func column(_ kind: ReportRange, _ h: EngineHarness) throws -> CalendarDayColumn {
        let key = DayKey(day(2026, 3, 4), calendar: h.engine.rangeCalendar)
        return try page(kind, h).find(CalendarDayColumn.self, where: { try $0.actualView().day == key }).actualView()
    }

    private func awayLabels(_ kind: ReportRange, _ h: EngineHarness) throws -> Int {
        try page(kind, h).findAll(where: { (try? $0.accessibilityIdentifier()) == "calendar.awayBackdrop.label" }).count
    }

    @Test func dayAndWeekPlaceTheSameBlocks() throws {
        let h = tracked()
        let day = try column(.day, h).placed
        let week = try column(.week, h).placed
        #expect(!day.isEmpty)
        #expect(day == week)
        #expect(day.contains { !$0.children.isEmpty })
    }

    @Test func weekAwayIsStripesWithNoLabel() throws {
        #expect(try awayLabels(.week, tracked()) == 0)
    }

    @Test func dayAwayKeepsThePill() throws {
        #expect(try awayLabels(.day, tracked()) == 1)
    }
}
