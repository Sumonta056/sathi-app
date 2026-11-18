import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar Day header")
struct CalendarDayHeaderTests {
    private var day: [CalendarLaidBlock] {
        [
            DayFix.away("Sleep", DayFix.at(7, 0), DayFix.at(9, 0)),
            DayFix.activity("Slides", DayFix.at(9, 0, 20), DayFix.at(10, 30, 10)),
            DayFix.activity("Code review", DayFix.at(11, 0), DayFix.at(12, 0)),
            DayFix.event("Friday Java Brief", DayFix.at(10, 6), DayFix.at(10, 36)),
            DayFix.event("Frontline Morning Scrum", DayFix.at(10, 30), DayFix.at(11, 0)),
            DayFix.event("Personal Editorial scrum", DayFix.at(13, 0), DayFix.at(13, 25)),
            DayFix.todo("Pay rent", DayFix.at(15, 0))
        ]
    }

    @Test func headerShowsActualAndPlan() throws {
        let sut = CalendarDayHeader(blocks: day, actualWidth: 300)
        #expect(throws: Never.self) { try sut.inspect().find(text: "Actual · 2h 30m") }
        #expect(throws: Never.self) { try sut.inspect().find(text: "Plan · 3 events") }
    }

    @Test func trackedLeavesAwayOutAndUsesRoundedLengths() {
        #expect(CalendarDayHeader.tracked(day) == 150 * 60)
    }

    @Test func trackedIsCutToThePageDay() {
        var a = DayFix.activity("Late", DayFix.at(5, 0, 0, on: 19), DayFix.at(7, 0, 0, on: 19))
        a.span = DateInterval(start: DayFix.at(5, 0, 0, on: 19), end: DayFix.at(6, 0, 0, on: 19))
        #expect(CalendarDayHeader.tracked([a]) == 60 * 60)
    }

    @Test func trackedCountsHiddenActivities() {
        var a = DayFix.activity("Slides", DayFix.at(9, 0), DayFix.at(10, 0))
        a.hidden = [DayFix.activity("Notes", DayFix.at(9, 10), DayFix.at(9, 40))]
        #expect(CalendarDayHeader.tracked([a]) == 90 * 60)
    }

    @Test func eventsCountsEventsNotTodosOrActivities() {
        #expect(CalendarDayHeader.events(day) == 3)
    }

    @Test func eventsCountsHiddenEvents() {
        var e = DayFix.event("Friday Java Brief", DayFix.at(10, 6), DayFix.at(10, 36))
        e.hidden = [DayFix.event("Frontline Morning Scrum", DayFix.at(10, 30), DayFix.at(11, 0))]
        #expect(CalendarDayHeader.events([e]) == 2)
    }
}
