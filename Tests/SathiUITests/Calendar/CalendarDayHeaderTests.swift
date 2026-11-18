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
    private typealias F = DayFix

    private var day: [CalendarLaidBlock] {
        [
            F.away("Sleep", F.at(7, 0), F.at(9, 0)),
            F.activity("Slides", F.at(9, 0, 20), F.at(10, 30, 10)),
            F.activity("Code review", F.at(11, 0), F.at(12, 0)),
            F.event("Friday Java Brief", F.at(10, 6), F.at(10, 36)),
            F.event("Frontline Morning Scrum", F.at(10, 30), F.at(11, 0)),
            F.event("Personal Editorial scrum", F.at(13, 0), F.at(13, 25)),
            F.todo("Pay rent", F.at(15, 0))
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
        var a = F.activity("Late", F.at(5, 0, 0, on: 19), F.at(7, 0, 0, on: 19))
        a.span = DateInterval(start: F.at(5, 0, 0, on: 19), end: F.at(6, 0, 0, on: 19))
        #expect(CalendarDayHeader.tracked([a]) == 60 * 60)
    }

    @Test func trackedCountsHiddenActivities() {
        var a = F.activity("Slides", F.at(9, 0), F.at(10, 0))
        a.hidden = [F.activity("Notes", F.at(9, 10), F.at(9, 40))]
        #expect(CalendarDayHeader.tracked([a]) == 90 * 60)
    }

    @Test func eventsCountsEventsNotTodosOrActivities() {
        #expect(CalendarDayHeader.events(day) == 3)
    }

    @Test func eventsCountsHiddenEvents() {
        var e = F.event("Friday Java Brief", F.at(10, 6), F.at(10, 36))
        e.hidden = [F.event("Frontline Morning Scrum", F.at(10, 30), F.at(11, 0))]
        #expect(CalendarDayHeader.events([e]) == 2)
    }
}
