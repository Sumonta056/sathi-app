import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar hover card info")
struct CalendarHoverInfoTests {
    private let cal = FixedZone.berlin.calendar
    private let lookup = CalendarHoverLookup(
        calendarNames: ["c": "Work"],
        readOnlyEventIDs: ["ro"],
        todoListNames: ["t1": "Groceries"],
        now: Lay.at(0),
        trackerOn: true
    )

    enum Kind: String, CaseIterable {
        case event, readOnlyEvent, activity, todo, away
    }

    private func block(_ k: Kind) -> CalendarBlock {
        switch k {
        case .event: return Lay.event("e1", 0, 90)
        case .readOnlyEvent: return Lay.event("ro", 0, 30)
        case .activity: return Lay.activity("Spec", 0, 45)
        case .todo:
            return CalendarBlock(
                id: "t-t1", title: "Buy milk", interval: DateInterval(start: Lay.at(30), end: Lay.at(30)),
                style: .todo(colorHex: 0), source: .todo("t1"), isAllDay: false, activityIDs: []
            )
        case .away:
            let a = Activity(kind: .away, text: "", start: Lay.at(0), end: Lay.at(60), awayPlace: .lunch)
            return CalendarBlock(
                id: "w", title: a.awayText, interval: a.interval, style: .away,
                source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
            )
        }
    }

    static func laid(_ b: CalendarBlock) -> CalendarLaidBlock {
        var half = CalendarHalf.plan
        if case .activity = b.source { half = .actual }
        return CalendarLaidBlock(block: b, span: b.interval, half: half, rounded: CalendarRounding.rounded(b.interval))
    }

    private func info(_ b: CalendarBlock) -> CalendarHoverInfo {
        CalendarHoverInfo.make(Self.laid(b), among: [], lookup: lookup, calendar: cal)
    }

    private static let expected: [Kind: (String, [CalendarHoverAction])] = [
        .event: ("Calendar event · Plan", [.startAsActivity, .edit, .openInCalendar]),
        .readOnlyEvent: ("Calendar event · Plan", [.startAsActivity, .openInCalendar]),
        .activity: ("Activity · Actual", [.edit, .delete]),
        .todo: ("To-do · Apple Reminders", [.markDone, .edit, .openInReminders]),
        .away: ("Away", [.editAway])
    ]

    @Test(arguments: Kind.allCases)
    func kindLineAndActionsPerKind(_ k: Kind) throws {
        let want = try #require(Self.expected[k])
        let i = info(block(k))
        #expect(i.kindLabel == want.0)
        #expect(i.actions == want.1)
    }

    @Test(arguments: Kind.allCases)
    func noKindOffersMergeOrSelectAll(_ k: Kind) {
        let labels = info(block(k)).actions.map(Copywriter.calendarHoverAction)
        #expect(!labels.contains("Merge"))
        #expect(!labels.contains("Select all"))
    }

    @Test func everyActionHasALabelAndNoneIsMerge() {
        let labels = CalendarHoverAction.allCases.map(Copywriter.calendarHoverAction)
        #expect(labels == ["Start as activity", "Edit", "Open in Calendar", "Delete", "Mark done", "Open in Reminders", "Edit Away"])
    }

    @Test func metaLinePerKind() {
        #expect(info(block(.event)).meta == "Work")
        #expect(info(block(.activity)).meta == "No category")
        #expect(info(block(.todo)).meta == "Groceries")
        #expect(info(block(.away)).meta == "Lunch")
    }

    @Test func eventInTwoCalendarsSaysSoInTheMetaLine() {
        var b = Lay.event("e1", 0, 30)
        b.copies = 2
        #expect(info(b).meta == "Work · in 2 calendars")
    }

    @Test func activityMetaIsItsCategory() {
        var b = Lay.activity("Spec", 0, 45)
        if case var .activity(a, running) = b.source {
            a.category = "Coding"
            b.source = .activity(a, running: running)
        }
        #expect(info(b).meta == "Coding")
    }

    @Test func todoShowsOnlyItsDueClock() {
        let i = info(block(.todo))
        #expect(i.title == "Buy milk")
        #expect(i.time == Copywriter.trackerClock(Lay.at(30), calendar: cal))
        #expect(i.length == nil)
    }

    @Test func lengthUsesTheShortForm() {
        #expect(info(Lay.event("e1", 0, 90)).length == "1h 30m")
    }

    @Test func runningActivityHasNoActions() {
        var b = Lay.activity("r", 0, 30)
        if case let .activity(a, _) = b.source { b.source = .activity(a, running: true) }
        #expect(info(b).actions.isEmpty)
    }

    @Test func blockWithNothingLinkedHasNoListTitles() {
        let i = info(Lay.event("e1", 0, 60))
        #expect(i.doneDuring.isEmpty)
        #expect(i.doneDuringTitle == nil)
        #expect(i.alsoHereTitle == nil)
        #expect(i.alsoHere.isEmpty)
    }
}
