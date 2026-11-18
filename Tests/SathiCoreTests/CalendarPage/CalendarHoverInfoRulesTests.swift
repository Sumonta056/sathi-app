import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar hover card action rules")
struct CalendarHoverInfoRulesTests {
    private let cal = FixedZone.berlin.calendar

    private func actions(_ block: CalendarBlock, now: Int = 0, trackerOn: Bool = true) -> [CalendarHoverAction] {
        let lookup = CalendarHoverLookup(now: Lay.at(now), trackerOn: trackerOn)
        return CalendarHoverInfo.make(CalendarPlacedBlock(block: block, lane: 0, lanes: 1), lookup: lookup, calendar: cal).actions
    }

    @Test func startAsActivityNeedsTheTrackerOn() {
        #expect(actions(Lay.event("e", 0, 60), now: 10, trackerOn: false) == [.edit, .openInCalendar])
    }

    @Test(arguments: [-5, 0, 30, 59])
    func startAsActivityShowsFromFiveMinutesBeforeUntilTheEnd(_ now: Int) {
        #expect(actions(Lay.event("e", 0, 60), now: now) == [.startAsActivity, .edit, .openInCalendar])
    }

    @Test(arguments: [-6, -24 * 60, 60, 90])
    func startAsActivityIsHiddenForAFutureOrPastEvent(_ now: Int) {
        #expect(actions(Lay.event("e", 0, 60), now: now) == [.edit, .openInCalendar])
    }

    @Test func runningActivityHasNoActions() {
        var b = Lay.activity("r", 0, 30)
        if case let .activity(a, _) = b.source { b.source = .activity(a, running: true) }
        #expect(actions(b).isEmpty)
    }

    @Test func weekJoinedBlockOfManyRowsHasNoDelete() {
        var b = Lay.activity("j", 0, 30)
        b.activityIDs.append(ActivityID())
        #expect(actions(b) == [.edit, .merge])
    }

    @Test func hiddenBlocksAreListedUnderAlsoHere() {
        var p = CalendarPlacedBlock(block: Lay.activity("a", 0, 60), lane: 0, lanes: 2)
        p.hidden = [
            CalendarPlacedBlock(block: Lay.event("Review", 10, 40), lane: 0, lanes: 1),
            CalendarPlacedBlock(block: Lay.activity("Notes", 12, 30), lane: 0, lanes: 1)
        ]
        let i = CalendarHoverInfo.make(p, lookup: CalendarHoverLookup(), calendar: cal)
        #expect(i.alsoHereTitle == "Also here")
        #expect(i.alsoHere == [
            CalendarHoverChild(id: "Review", title: "Review", time: Fmt.shortRange(Lay.at(10), Lay.at(40), calendar: cal)),
            CalendarHoverChild(id: "Notes", title: "Notes", time: Fmt.shortRange(Lay.at(12), Lay.at(30), calendar: cal))
        ])
    }

    @Test func blockWithNothingHiddenHasNoAlsoHere() {
        let i = CalendarHoverInfo.make(
            CalendarPlacedBlock(block: Lay.event("e", 0, 60), lane: 0, lanes: 1),
            lookup: CalendarHoverLookup(),
            calendar: cal
        )
        #expect(i.alsoHereTitle == nil)
        #expect(i.alsoHere.isEmpty)
    }
}
