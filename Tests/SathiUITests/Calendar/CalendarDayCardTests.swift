import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar Day card")
struct CalendarDayCardTests {
    private typealias F = DayFix

    private func shows(_ view: some View, _ text: String) -> Bool {
        (try? view.inspect().find(text: text)) != nil
    }

    private var codeReview: CalendarLaidBlock {
        F.activity("Code review", F.at(10, 38, 16), F.at(12, 30, 57), eventID: "ev-1", top: 278, bottom: 391)
    }

    @Test func activityCardShowsEveryField() {
        let sut = F.card(codeReview)
        #expect(shows(sut, "Code review"))
        #expect(shows(sut, "10:38 AM – 12:31 PM"))
        #expect(shows(sut, "Coding Hobby"))
        #expect(shows(sut, "Calendar"))
        #expect(shows(sut, "1h 53m"))
        #expect(!shows(sut, "Not in calendar"))
    }

    @Test func activityWithoutAnEventSaysNotInCalendar() {
        let sut = F.card(F.activity("Code review", F.at(10, 38, 16), F.at(12, 30, 57)))
        #expect(shows(sut, "Not in calendar"))
        #expect(!shows(sut, "Calendar"))
    }

    @Test func shortActivityAtTheMinimumHeightKeepsItsTimeAndLength() {
        let short = F.activity("Stretch", F.at(12, 30, 57), F.at(12, 35, 57), bottom: UIMetrics.calendarDayCardMinHeight)
        let sut = F.card(short)
        #expect(shows(sut, "Stretch"))
        #expect(shows(sut, "12:31 – 12:36 PM"))
        #expect(shows(sut, "5m"))
        #expect(shows(sut, "Coding Hobby"))
    }

    @Test func runningActivityIsAnActivityCard() {
        let running = F.activity("Code review", F.at(10, 38), F.at(11, 8), running: true)
        let sut = F.card(running)
        #expect(shows(sut, "Coding Hobby"))
        #expect(shows(sut, "30m"))
        #expect((try? sut.inspect().find(viewWithAccessibilityIdentifier: "calendar.day.edit")) != nil)
    }

    @Test func awayCardShowsReasonTimeAndLength() {
        let sut = F.card(F.away("Sleep", F.at(7, 0), F.at(9, 34, 28)))
        #expect(shows(sut, "Away · Sleep"))
        #expect(shows(sut, "7:00 – 9:34 AM"))
        #expect(shows(sut, "2h 34m"))
    }

    @Test func eventCardShowsCalendarNameAndDoneDuring() throws {
        var e = F.event("Personal Editorial scrum", F.at(13, 0), F.at(13, 25))
        e.doneDuringCount = 1
        let sut = F.card(e, calendarName: "Work")
        #expect(shows(sut, "Personal Editorial scrum"))
        #expect(shows(sut, "1:00 – 1:25 PM"))
        #expect(shows(sut, "Work"))
        #expect(shows(sut, "1 done during"))
        #expect(shows(sut, "25m"))
        let names = try sut.inspect().findAll(ViewType.Image.self).compactMap { try? $0.actualImage().name() }
        #expect(names.contains("calendar"))
    }

    @Test func eventWithNothingDoneDuringHasNoTag() {
        let sut = F.card(F.event("Frontline Morning Scrum", F.at(10, 30), F.at(11, 0)), calendarName: "Work")
        #expect(!shows(sut, "0 done during"))
        #expect(shows(sut, "30m"))
    }

    @Test func pencilCallsEdit() throws {
        var edits = 0
        let sut = F.card(codeReview) { edits += 1 }
        try sut.inspect().find(viewWithAccessibilityIdentifier: "calendar.day.edit").button().tap()
        #expect(edits == 1)
    }

    @Test func todoDrawsNothing() {
        let sut = F.card(F.todo("Pay rent", F.at(15, 0)))
        #expect((try? sut.inspect().find(ViewType.Text.self)) == nil)
    }

    @Test func twoLinesFitTheMinimumHeights() {
        #expect(CalendarDayCardFit.twoLineHeight(away: false) > 0)
        #expect(CalendarDayCardFit.twoLineHeight(away: false) <= UIMetrics.calendarDayCardMinHeight)
        #expect(CalendarDayCardFit.twoLineHeight(away: true) > 0)
        #expect(CalendarDayCardFit.twoLineHeight(away: true) <= UIMetrics.calendarDayAwayMinHeight)
    }

    @Test func titleWrapsUpToThreeLinesWhenTall() {
        #expect(CalendarDayCardFit.titleLines(height: UIMetrics.calendarDayCardMinHeight) == 1)
        #expect(CalendarDayCardFit.titleLines(height: 400) == 3)
    }

    @Test func darkCalendarColorIsMadeLighterForText() {
        #expect(CalendarDayTextColor.hex(0x1F3A93) == 0x919FCC)
        #expect(CalendarDayTextColor.hex(0x7FB8FF) == 0x7FB8FF)
    }
}
