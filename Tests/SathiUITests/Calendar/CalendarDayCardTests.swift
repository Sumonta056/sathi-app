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
    private func shows(_ view: some View, _ text: String) -> Bool {
        (try? view.inspect().find(text: text)) != nil
    }

    private var codeReview: CalendarLaidBlock {
        DayFix.activity("Code review", DayFix.at(10, 38, 16), DayFix.at(12, 30, 57), eventID: "ev-1", top: 278, bottom: 391)
    }

    @Test func activityCardShowsEveryField() {
        let sut = DayFix.card(codeReview)
        #expect(shows(sut, "Code review"))
        #expect(shows(sut, "10:38 AM – 12:31 PM"))
        #expect(shows(sut, "Coding Hobby"))
        #expect(shows(sut, "Calendar"))
        #expect(shows(sut, "1h 53m"))
        #expect(!shows(sut, "Not in calendar"))
    }

    @Test func activityWithoutAnEventSaysNotInCalendar() {
        let sut = DayFix.card(DayFix.activity("Code review", DayFix.at(10, 38, 16), DayFix.at(12, 30, 57)))
        #expect(shows(sut, "Not in calendar"))
        #expect(!shows(sut, "Calendar"))
    }

    @Test func shortActivityAtTheMinimumHeightKeepsItsTimeAndLength() {
        let short = DayFix.activity("Stretch", DayFix.at(12, 30, 57), DayFix.at(12, 35, 57), bottom: UIMetrics.calendarDayCardMinHeight)
        let sut = DayFix.card(short)
        #expect(shows(sut, "Stretch"))
        #expect(shows(sut, "12:31 – 12:36 PM"))
        #expect(shows(sut, "5m"))
        #expect(shows(sut, "Coding Hobby"))
    }

    @Test func runningActivityIsAnActivityCard() {
        let running = DayFix.activity("Code review", DayFix.at(10, 38), DayFix.at(11, 8), running: true)
        let sut = DayFix.card(running)
        #expect(shows(sut, "Coding Hobby"))
        #expect(shows(sut, "30m"))
        #expect((try? sut.inspect().find(viewWithAccessibilityIdentifier: "calendar.day.edit")) != nil)
    }

    @Test func awayCardShowsReasonTimeAndLength() {
        let sut = DayFix.card(DayFix.away("Sleep", DayFix.at(7, 0), DayFix.at(9, 34, 28)))
        #expect(shows(sut, "Away · Sleep"))
        #expect(shows(sut, "7:00 – 9:34 AM"))
        #expect(shows(sut, "2h 34m"))
    }

    @Test func eventCardShowsCalendarNameAndDoneDuring() throws {
        var e = DayFix.event("Personal Editorial scrum", DayFix.at(13, 0), DayFix.at(13, 25))
        e.doneDuringCount = 1
        let sut = DayFix.card(e, calendarName: "Work")
        #expect(shows(sut, "Personal Editorial scrum"))
        #expect(shows(sut, "1:00 – 1:25 PM"))
        #expect(shows(sut, "Work"))
        #expect(shows(sut, "1 done during"))
        #expect(shows(sut, "25m"))
        let names = try sut.inspect().findAll(ViewType.Image.self).compactMap { try? $0.actualImage().name() }
        #expect(names.contains("calendar"))
    }

    @Test func eventWithNothingDoneDuringHasNoTag() {
        let sut = DayFix.card(DayFix.event("Frontline Morning Scrum", DayFix.at(10, 30), DayFix.at(11, 0)), calendarName: "Work")
        #expect(!shows(sut, "0 done during"))
        #expect(shows(sut, "30m"))
    }

    @Test func pencilCallsEdit() throws {
        var edits = 0
        let sut = DayFix.card(codeReview) { edits += 1 }
        try sut.inspect().find(viewWithAccessibilityIdentifier: "calendar.day.edit").button().tap()
        #expect(edits == 1)
    }

    @Test(arguments: ["activity", "away", "event"])
    func theCardBodyHasNoTapOfItsOwn(_ kind: String) throws {
        var edits = 0
        let laid = switch kind {
        case "away": DayFix.away("Sleep", DayFix.at(7, 0), DayFix.at(9, 34, 28))
        case "event": DayFix.event("Frontline Morning Scrum", DayFix.at(10, 30), DayFix.at(11, 0))
        default: codeReview
        }
        let sut = try DayFix.card(laid) { edits += 1 }.inspect()
        for view in sut.findAll(where: { _ in true }) {
            try? view.callOnTapGesture()
        }
        #expect(edits == 0)
    }

    @Test func todoDrawsNothing() {
        let sut = DayFix.card(DayFix.todo("Pay rent", DayFix.at(15, 0)))
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
