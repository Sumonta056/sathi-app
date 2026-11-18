import Foundation
@testable import SathiCore
import Testing

@Suite("Calendar done during")
struct CalendarDoneDuringTests {
    private let meeting = Split.span("10:00", "11:00")

    @Test(arguments: [
        ("10:00", "10:20", true),
        ("09:55", "10:30", true),
        ("09:54", "10:30", false),
        ("10:30", "11:30", true),
        ("10:31", "11:31", false),
        ("10:50", "11:00", true),
        ("11:00", "11:30", false),
        ("09:00", "09:30", false),
        ("09:56", "10:03", false),
        ("09:56", "10:04", true)
    ])
    func fits(_ from: String, _ to: String, _ expected: Bool) {
        #expect(CalendarDoneDuring.fits(Split.span(from, to), in: meeting) == expected)
    }

    @Test func layoutLinksActivitiesToTheirEvent() {
        let grid = Split.layout([
            Split.event("meet", "10:00", "11:00"), Split.activity("a1", "10:00", "10:20"),
            Split.activity("a2", "10:25", "10:50"), Split.activity("a3", "10:40", "11:40"), Split.activity("a4", "12:00", "12:30")
        ])
        #expect(Split.laid(grid, "a1")?.doneDuring == "meet")
        #expect(Split.laid(grid, "a2")?.doneDuring == "meet")
        #expect(Split.laid(grid, "a3")?.doneDuring == nil)
        #expect(Split.laid(grid, "a4")?.doneDuring == nil)
        #expect(Split.laid(grid, "meet")?.doneDuringCount == 2)
    }

    @Test func eventWithNothingDoneDuringCountsZero() {
        let grid = Split.layout([Split.event("meet", "10:00", "11:00"), Split.activity("later", "11:00", "11:30")])
        #expect(Split.laid(grid, "meet")?.doneDuringCount == 0)
        #expect(Split.laid(grid, "later")?.doneDuring == nil)
        #expect(Split.laid(grid, "meet")?.doneDuring == nil)
    }

    @Test func doneDuringActivityStaysInActualAtItsOwnTime() {
        let grid = Split.layout([Split.event("meet", "10:00", "11:00"), Split.activity("a1", "10:20", "10:50")])
        let a1 = Split.laid(grid, "a1")
        #expect(a1?.half == .actual)
        #expect(a1?.top == 260)
        #expect(a1?.lanes == 1)
        #expect(a1?.depth == 0)
    }

    @Test func limitsMatchTheRule() {
        #expect(Limits.calendarHostLeadMinutes == 5)
        #expect(Limits.calendarHostShare == 0.5)
    }

    @Test func activityLinksToTheFirstMatchingEventOnly() {
        let grid = Split.layout([
            Split.event("late", "10:10", "10:40"), Split.event("early", "10:00", "11:00"), Split.activity("a", "10:12", "10:30")
        ])
        #expect(Split.laid(grid, "a")?.doneDuring == "early")
        #expect(Split.laid(grid, "early")?.doneDuringCount == 1)
        #expect(Split.laid(grid, "late")?.doneDuringCount == 0)
    }

    @Test func eventsAndActivitiesNeverSwapRoles() {
        let grid = Split.layout([
            Split.activity("big", "10:00", "11:00"), Split.activity("small", "10:10", "10:20"),
            Split.event("meet", "12:00", "13:00"), Split.event("inside", "12:10", "12:20")
        ])
        #expect(Split.laid(grid, "small")?.doneDuring == nil)
        #expect(Split.laid(grid, "inside")?.doneDuring == nil)
        #expect(Split.laid(grid, "meet")?.doneDuringCount == 0)
    }

    @Test func awayIsNeverDoneDuring() {
        let grid = Split.layout([Split.event("meet", "10:00", "11:00"), Split.away("away", "10:10", "10:30")])
        #expect(Split.laid(grid, "away")?.doneDuring == nil)
        #expect(Split.laid(grid, "meet")?.doneDuringCount == 0)
    }
}

@Suite("Calendar done during: real times")
struct CalendarDoneDuringUncutTests {
    @Test func activityBeforeTheEventStartsIsNotLinkedInTheNextColumn() {
        let tuesday = Split.monday + 1
        let real = DateInterval(start: Split.at("05:30"), end: Split.at("06:30", on: tuesday))
        let grid = Split.layout(
            [Split.event("early", "06:00", "07:00", on: tuesday), Split.activity("run", real)],
            days: [Split.page, Split.key(tuesday)], metrics: Split.weekFlat
        )
        let key = Split.key(tuesday)
        #expect(Split.laid(grid, "run", on: key) != nil)
        #expect(Split.laid(grid, "run", on: key)?.doneDuring == nil)
        #expect(Split.laid(grid, "early", on: key)?.doneDuringCount == 0)
    }
}
