import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockHost")
struct CalendarBlockHostTests {
    func hosts(_ blocks: [CalendarBlock]) -> [String: String] {
        CalendarBlockHost.hosts(blocks.map { (block: $0, span: $0.interval) })
    }

    @Test func limitsMatchTheRule() {
        #expect(Limits.calendarHostLeadMinutes == 5)
        #expect(Limits.calendarHostShare == 0.5)
    }

    @Test func shortActivityInsideAnEventIsAChild() {
        #expect(hosts([Lay.event("e", 0, 30), Lay.activity("a", 4, 26)]) == ["a": "e"])
    }

    @Test func longActivityWithASmallOverlapIsNotAChild() {
        #expect(hosts([Lay.event("e", 0, 30), Lay.activity("a", 0, 82)]).isEmpty)
    }

    @Test func activityStartingTheLeadBeforeTheEventIsAChild() {
        #expect(hosts([Lay.event("e", 10, 40), Lay.activity("a", 5, 35)]) == ["a": "e"])
    }

    @Test func activityStartingEarlierThanTheLeadIsNotAChild() {
        #expect(hosts([Lay.event("e", 10, 70), Lay.activity("a", 0, 60)]).isEmpty)
    }

    @Test func overlapOfExactlyHalfIsAChild() {
        #expect(hosts([Lay.event("e", 0, 30), Lay.activity("a", 15, 45)]) == ["a": "e"])
    }

    @Test func activityGetsTheFirstMatchingEventOnly() {
        #expect(hosts([Lay.event("late", 10, 40), Lay.event("early", 0, 60), Lay.activity("a", 12, 30)]) == ["a": "early"])
    }

    @Test func eventsAndActivitiesNeverSwapRoles() {
        #expect(hosts([Lay.activity("big", 0, 60), Lay.activity("small", 10, 20)]).isEmpty)
        #expect(hosts([Lay.event("big", 0, 60), Lay.event("small", 10, 20)]).isEmpty)
    }

    @Test func awayIsNeverAChild() {
        #expect(hosts([Lay.event("e", 0, 60), Lay.away("w", 10, 30)]).isEmpty)
    }

    @Test func touchingActivityIsNotAChild() {
        #expect(hosts([Lay.event("e", 0, 30), Lay.activity("a", 30, 40)]).isEmpty)
    }

    @Test func layoutPutsTheChildInsideItsHost() {
        let placed = CalendarBlockLayout.place([Lay.event("e", 0, 30), Lay.activity("a", 4, 26)])
        #expect(placed.map(\.block.id) == ["e"])
        #expect(placed.first?.children.map(\.block.id) == ["a"])
        #expect(placed.first?.children.first?.hostID == "e")
        #expect(placed.first?.children.first?.span == Lay.span(4, 26))
        #expect(placed.first?.lanes == 1)
    }
}
