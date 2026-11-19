import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar week day count")
struct CalendarWeekDaysTests {
    private final class Box {
        var range: CalendarPageRange
        init(_ range: CalendarPageRange) { self.range = range }
        var binding: Binding<CalendarPageRange> { Binding(get: { self.range }, set: { self.range = $0 }) }
    }

    private func page(_ h: EngineHarness, _ kind: ReportRange) throws -> InspectableView<ViewType.ClassifiedView> {
        let range = CalendarPageRange.containing(day(2026, 3, 4, 12), kind: kind, calendar: h.engine.rangeCalendar)
        return try CalendarPage(range: range).environmentObject(h.engine).inspect()
    }

    @Test func weekShowsTheFourDayCounts() throws {
        let sut = try page(EngineHarness(at: day(2026, 3, 4, 12)), .week)
        for text in ["3 days", "4 days", "5 days", "7 days"] {
            #expect(throws: Never.self) { try sut.find(ViewType.Menu.self).find(button: text) }
        }
    }

    @Test func theDayCountIsAMenuThatListsTheFourCounts() throws {
        let menu = try CalendarWeekDaysControl(days: 7) { _ in }.inspect().find(ViewType.Menu.self)
        let titles = try menu.findAll(ViewType.Button.self).map { try $0.labelView().text().string() }
        #expect(titles == ["3 days", "4 days", "5 days", "7 days"])
    }

    @Test func theMenuButtonShowsTheCurrentCount() throws {
        let menu = try CalendarWeekDaysControl(days: 5) { _ in }.inspect().find(ViewType.Menu.self)
        #expect(throws: Never.self) { try menu.labelView().find(text: "5 days") }
        #expect(throws: Never.self) { try menu.labelView().find(ViewType.Image.self) }
    }

    @Test func aMenuPickSendsTheCount() throws {
        var picked: [Int] = []
        let menu = try CalendarWeekDaysControl(days: 7) { picked.append($0) }.inspect().find(ViewType.Menu.self)
        try menu.find(button: "4 days").tap()
        #expect(picked == [4])
    }

    @Test(arguments: [ReportRange.day, .month])
    func otherViewsHaveNoDayCount(_ kind: ReportRange) throws {
        let sut = try page(EngineHarness(at: day(2026, 3, 4, 12)), kind)
        #expect(Find.lacks(sut, text: "3 days"))
    }

    @Test func aTapSavesTheCount() throws {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        try page(h, .week).find(ViewType.Menu.self).find(button: "4 days").tap()
        #expect(h.engine.data.prefs.calendarPage.weekDays == 4)
    }

    @Test func pickingACountResetsTheRangeToTheDefaultRangeOfThatCount() {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        let range = CalendarPage.pickDays(5, engine: h.engine)
        #expect(h.engine.data.prefs.calendarPage.weekDays == 5)
        #expect(range == h.engine.calendarPageToday(.week))
        #expect(range.days.count == 5)
    }

    @Test func theHeaderDayCountSendsThePickedCount() throws {
        let b = Box(.containing(day(2026, 3, 4, 12), kind: .week, calendar: .current))
        var picked: [Int] = []
        let header = CalendarPageHeader(range: b.binding, now: day(2026, 3, 4, 12), calendar: .current, weekDays: 7) { picked.append($0) }
        try header.inspect().find(ViewType.Menu.self).find(button: "3 days").tap()
        #expect(picked == [3])
    }

    @Test func todayUsesTheGivenTodayRange() throws {
        let h = EngineHarness(at: day(2026, 3, 4, 12)) { $0.prefs.calendarPage.weekDays = 3 }
        let b = Box(.containing(day(2026, 2, 4, 12), kind: .week, calendar: h.engine.rangeCalendar, weekDays: 3))
        let header = CalendarPageHeader(
            range: b.binding, now: day(2026, 3, 4, 12), calendar: h.engine.rangeCalendar, today: h.engine.calendarPageToday
        )
        try Find.button(header.inspect(), holding: "Today").tap()
        #expect(b.range == h.engine.calendarPageToday(.week))
    }
}
