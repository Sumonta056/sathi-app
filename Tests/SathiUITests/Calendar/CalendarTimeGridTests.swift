import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar time grid")
struct CalendarTimeGridTests {
    private let z = FixedZone.berlin

    private func grid(_ range: CalendarPageRange, now: Date, rowMinutes: Int = 60) -> CalendarTimeGrid {
        let data = CalendarPageData(range: range, allDay: [], blocks: [], stats: CalendarPageStats(), monthCells: [], texts: [:])
        return CalendarTimeGrid(range: range, data: data, now: now, calendar: z.calendar, categories: [], rowMinutes: rowMinutes)
    }

    @Test(arguments: [(60, 0), (30, 24), (15, 72)])
    func zoomAddsFaintLinesInsideEachHour(_ minutes: Int, _ lines: Int) throws {
        let now = z.date(2026, 11, 12, 15, 20)
        let day = CalendarPageRange.containing(now, kind: .day, calendar: z.calendar)
        let sut = try grid(day, now: now, rowMinutes: minutes).inspect()
        #expect(sut.findAll(where: { (try? $0.accessibilityIdentifier()) == "calendar.subline" }).count == lines)
    }

    @Test func hourLabelsRunFromSixAMWithoutRepeats() {
        let labels = CalendarTimeGrid.hourLabels
        #expect(labels.count == 24)
        #expect(Set(labels).count == 24)
        #expect(labels.first == "6 AM")
        #expect(labels[6] == "Midday")
        #expect(labels[20] == "2 AM")
        #expect(labels.last == "5 AM")
    }

    @Test func springForwardDayShowsThreeAMOnce() throws {
        let range = CalendarPageRange.containing(z.date(2026, 3, 28, 12), kind: .day, calendar: z.calendar)
        let sut = try grid(range, now: z.date(2026, 3, 28, 12)).inspect()
        #expect(sut.findAll(ViewType.Text.self, where: { (try? $0.string()) == "3 AM" }).count == 1)
        #expect(throws: Never.self) { try sut.find(text: "2 AM") }
    }

    @Test func gridHidesTheScrollBar() throws {
        let now = z.date(2026, 11, 12, 15, 20)
        let week = CalendarPageRange.containing(now, kind: .week, calendar: z.calendar)
        let scroll = try grid(week, now: now).inspect().find(ViewType.ScrollView.self)
        #expect(try scroll.showsIndicators() == false)
    }

    @Test func initialRowIsTheRowOfNow() {
        let now = z.date(2026, 11, 12, 15, 20)
        let week = CalendarPageRange.containing(now, kind: .week, calendar: z.calendar)
        #expect(grid(week, now: now).initialRow == 9)
    }

    @Test func initialRowIsSixAMForAnotherRange() {
        let now = z.date(2026, 11, 12, 15, 20)
        let past = CalendarPageRange.containing(z.date(2026, 10, 1, 12), kind: .day, calendar: z.calendar)
        #expect(grid(past, now: now).initialRow == 0)
    }
}
