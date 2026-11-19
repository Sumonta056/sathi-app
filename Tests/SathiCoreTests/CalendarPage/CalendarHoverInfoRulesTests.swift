import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar hover card rules")
struct CalendarHoverInfoRulesTests {
    private let berlin = FixedZone.berlin.calendar
    private let wednesday = 18

    private func actions(_ block: CalendarBlock, now: Int, trackerOn: Bool = true) -> [CalendarHoverAction] {
        let lookup = CalendarHoverLookup(now: Lay.at(now), trackerOn: trackerOn)
        return CalendarHoverInfo.make(CalendarHoverInfoTests.laid(block), among: [], lookup: lookup, calendar: berlin).actions
    }

    private func info(_ laid: CalendarLaidBlock, among: [CalendarLaidBlock] = []) -> CalendarHoverInfo {
        CalendarHoverInfo.make(laid, among: among, lookup: CalendarHoverLookup(), calendar: Split.calendar)
    }

    @Test(arguments: [0, -5, 30])
    func startAsActivityShowsFromFiveMinutesBeforeTheStart(_ now: Int) {
        #expect(actions(Lay.event("e", 0, 60), now: now) == [.startAsActivity, .edit, .openInCalendar])
    }

    @Test(arguments: [-6, 60])
    func startAsActivityIsHiddenSixMinutesBeforeOrAfterTheEnd(_ now: Int) {
        #expect(actions(Lay.event("e", 0, 60), now: now) == [.edit, .openInCalendar])
    }

    @Test func startAsActivityNeedsTheTrackerOn() {
        #expect(actions(Lay.event("e", 0, 60), now: 0, trackerOn: false) == [.edit, .openInCalendar])
    }

    @Test func readOnlyEventHasNoEdit() {
        let lookup = CalendarHoverLookup(readOnlyEventIDs: ["e"], now: Lay.at(-60), trackerOn: true)
        let i = CalendarHoverInfo.make(CalendarHoverInfoTests.laid(Lay.event("e", 0, 60)), among: [], lookup: lookup, calendar: berlin)
        #expect(i.actions == [.openInCalendar])
    }

    @Test func timeAndLengthAreRoundedOnce() throws {
        let b = Split.activity("Review", "14:35:54", "15:01:32", on: wednesday)
        let laid = try #require(Split.laid(Split.layout([b], days: [Split.key(wednesday)]), "Review", on: Split.key(wednesday)))
        let i = info(laid)
        #expect(i.time == "2:36 – 3:02 PM")
        #expect(i.length == "26m")
    }

    @Test func anEventListsItsDoneDuringActivitiesFromTheDay() throws {
        let key = Split.key(wednesday)
        let scrum = Split.event("Frontline Morning Scrum", "10:30", "11:00", on: wednesday)
        let notes = Split.activity("Scrum notes", "10:31:20", "10:58:40", on: wednesday)
        let other = Split.activity("Code review", "12:00", "12:30", on: wednesday)
        let grid = Split.layout([scrum, notes, other], days: [key])
        let day = try #require(grid.days[key])
        let event = try #require(Split.laid(grid, "Frontline Morning Scrum", on: key))
        let i = info(event, among: day)
        #expect(i.doneDuringTitle == "Done during this event")
        #expect(i.doneDuring == [CalendarHoverChild(id: "Scrum notes", title: "Scrum notes", time: "10:31 – 10:59 AM")])
    }

    @Test func anActivityListsNoDoneDuringRows() throws {
        let key = Split.key(wednesday)
        let grid = Split.layout(
            [Split.event("Frontline Morning Scrum", "10:30", "11:00", on: wednesday), Split.activity("Notes", "10:31", "10:58", on: wednesday)],
            days: [key]
        )
        let activity = try #require(Split.laid(grid, "Notes", on: key))
        #expect(info(activity, among: grid.days[key] ?? []).doneDuring.isEmpty)
    }

    @Test func alsoHereListsTheHiddenItemsWithRoundedShortTimes() {
        var top = CalendarHoverInfoTests.laid(Split.event("Brief", "10:00", "11:00", on: wednesday))
        top.hidden = [
            CalendarHoverInfoTests.laid(Split.event("Review", "10:10:40", "10:40", on: wednesday)),
            CalendarHoverInfoTests.laid(Split.event("Sync", "10:12", "10:30", on: wednesday))
        ]
        let i = info(top)
        #expect(i.alsoHereTitle == "Also here")
        #expect(i.alsoHere == [
            CalendarHoverChild(id: "Review", title: "Review", time: "10:11 – 10:40 AM"),
            CalendarHoverChild(id: "Sync", title: "Sync", time: "10:12 – 10:30 AM")
        ])
    }
}
