import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar block badges")
struct CalendarBlockBadgesTests {
    private func shows(_ view: some View, _ text: String) -> Bool {
        (try? view.inspect().find(text: text)) != nil
    }

    private var ticket: CalendarLaidBlock {
        var e = DayFix.event("Air Ticket", DayFix.at(9, 0), DayFix.at(10, 0))
        e.block.copies = 2
        return e
    }

    @Test func dayEventCardWithOneHiddenItemShowsPlusOne() {
        var e = DayFix.event("Scrum", DayFix.at(10, 30), DayFix.at(11, 0))
        e.hidden = [DayFix.event("Sync", DayFix.at(10, 35), DayFix.at(11, 0))]
        #expect(shows(DayFix.card(e, calendarName: "Work"), "+1"))
    }

    @Test func dayEventInTwoCalendarsShowsTimesTwo() {
        let sut = DayFix.card(ticket, calendarName: "Work")
        #expect(shows(sut, "×2"))
        #expect(!shows(sut, "+1"))
    }

    @Test func dayActivityCardWithOneHiddenItemShowsPlusOne() {
        var a = DayFix.activity("Code review", DayFix.at(10, 38), DayFix.at(11, 30))
        a.hidden = [DayFix.activity("Lunch", DayFix.at(10, 40), DayFix.at(11, 0))]
        #expect(shows(DayFix.card(a), "+1"))
    }

    @Test func dayAwayCardWithOneHiddenItemShowsPlusOne() {
        var a = DayFix.away("Sleep", DayFix.at(7, 0), DayFix.at(9, 0))
        a.hidden = [DayFix.away("Gym", DayFix.at(7, 10), DayFix.at(8, 0))]
        #expect(shows(DayFix.card(a), "+1"))
    }

    @Test func dayCardWithoutHiddenOrCopiesHasNoBadge() {
        let sut = DayFix.card(DayFix.event("Scrum", DayFix.at(10, 30), DayFix.at(11, 0)), calendarName: "Work")
        #expect(!shows(sut, "+1"))
        #expect(!shows(sut, "×1"))
    }

    @Test func weekBlockWithTwoCopiesShowsTimesTwo() {
        let sut = CalendarWeekBlock(
            laid: ticket, size: CGSize(width: 160, height: 46), narrow: false, calendar: DayFix.calendar, categories: []
        )
        #expect(shows(sut, "×2"))
    }
}
