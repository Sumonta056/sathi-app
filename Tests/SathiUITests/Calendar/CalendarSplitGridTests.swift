import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar split grid")
struct CalendarSplitGridTests {
    typealias Fix = CalendarSplitViewFixtures

    private func grid(_ range: CalendarPageRange, _ layout: CalendarGridLayout, now: Date = Fix.at(12)) -> CalendarSplitGrid {
        CalendarSplitGrid(range: range, data: Fix.data(range, grid: layout), now: now, calendar: Fix.cal, categories: [])
    }

    @Test func weekHeadersShowWeekdayDayAndMonth() throws {
        let sut = try grid(Fix.weekRange(3), Fix.grid([:])).inspect()
        for text in ["Sun 15 Nov", "Mon 16 Nov", "Tue 17 Nov"] {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
    }

    @Test func weekHasActualAndPlanLabelsUnderEachDay() throws {
        let sut = try grid(Fix.weekRange(3), Fix.grid([:])).inspect()
        #expect(sut.findAll(ViewType.Text.self, where: { try $0.string() == "ACTUAL" }).count == 3)
        #expect(sut.findAll(ViewType.Text.self, where: { try $0.string() == "PLAN" }).count == 3)
    }

    @Test func dayHasNoWeekLabelsAndShowsTheDayHeader() throws {
        let sut = try grid(Fix.dayRange(), Fix.grid([:])).inspect()
        #expect(Find.lacks(sut, text: "ACTUAL"))
        #expect(throws: Never.self) { try sut.find(CalendarDayHeader.self) }
    }

    @Test func aFoldRowIsAStripWithItsText() throws {
        let rows = Fix.rows([
            Fix.Row(start: 0, end: 60, height: 60),
            Fix.Row(start: 60, end: 180, height: 22, fold: true),
            Fix.Row(start: 180, end: 240, height: 60)
        ])
        let sut = try grid(Fix.weekRange(3), Fix.grid([:], rows: rows)).inspect()
        #expect(throws: Never.self) { try sut.find(text: "7:00 – 9:00 AM · away or nothing on every shown day") }
    }

    @Test func theRailLabelsTheHourRows() throws {
        let sut = try grid(Fix.dayRange(), Fix.grid([:])).inspect()
        for text in ["6 AM", "Midday", "5 AM"] {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
    }

    @Test func theNowLineShowsOnlyInTodaysColumn() throws {
        let sut = try grid(Fix.weekRange(3), Fix.grid([:])).inspect()
        #expect(sut.findAll(CalendarNowLine.self).count == 1)
    }

    @Test func theGridHidesTheScrollBar() throws {
        let scroll = try grid(Fix.weekRange(3), Fix.grid([:])).inspect().find(ViewType.ScrollView.self)
        #expect(try scroll.showsIndicators() == false)
    }

    @Test func weekDrawsWeekBlocksAndDayDrawsDayCards() throws {
        let a = Fix.laid(Fix.activity("Write", Fix.at(10), Fix.at(11)), top: 240, bottom: 300)
        let week = try grid(Fix.weekRange(3), Fix.grid([Fix.monday: [a]])).inspect()
        #expect(week.findAll(CalendarWeekBlock.self).count == 1)
        #expect(week.findAll(CalendarDayCard.self).isEmpty)
        let day = try grid(Fix.dayRange(), Fix.grid([Fix.monday: [a]])).inspect()
        #expect(day.findAll(CalendarDayCard.self).count == 1)
        #expect(day.findAll(CalendarWeekBlock.self).isEmpty)
    }

    @Test func dayDrawsTheDoneDuringLinks() throws {
        let sut = try grid(Fix.dayRange(), Fix.grid([:])).inspect()
        #expect(throws: Never.self) { try sut.find(CalendarDayLinks.self) }
    }

    @Test func hoverRingUsesTheDayCardRadiusInDay() {
        let laid = Fix.laid(Fix.event("Scrum", Fix.at(10), Fix.at(11)), top: 0, bottom: 60)
        #expect(CalendarSplitGrid.ringRadius(laid, kind: .day) == UIMetrics.calendarDayCardRadius)
    }

    @Test func hoverRingUsesTheWeekBlockRadiusInWeek() {
        let laid = Fix.laid(Fix.event("Scrum", Fix.at(10), Fix.at(11)), top: 0, bottom: 60)
        #expect(CalendarSplitGrid.ringRadius(laid, kind: .week) == UIMetrics.calendarWeekBlockRadius)
    }

    @Test(arguments: [ReportRange.day, .week])
    func hoverRingOnAToDoPillIsRound(_ kind: ReportRange) {
        let laid = Fix.laid(Fix.todo("Pay rent", Fix.at(15)), top: 0, bottom: 22)
        #expect(CalendarSplitGrid.ringRadius(laid, kind: kind) == UIMetrics.calendarTodoPillHeight / 2)
    }
}
