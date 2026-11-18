import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockBuilder")
struct CalendarBlockBuilderTests {
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func event(
        _ id: String,
        _ title: String = "Event",
        at minutes: Int = 0,
        length: Int = 30,
        allDay: Bool = false,
        calendar: String = "c1"
    ) -> CalendarEventInfo {
        CalendarEventInfo(
            id: id, title: title, start: t0.addingTimeInterval(TimeInterval(minutes * 60)),
            end: t0.addingTimeInterval(TimeInterval((minutes + length) * 60)), calendarID: calendar, isAllDay: allDay
        )
    }

    func activity(
        _ text: String = "Focus",
        kind: ActivityKind = .work,
        at minutes: Int = 0,
        length: Int = 30,
        eventID: String? = nil,
        sourceEventID: String? = nil
    ) -> Activity {
        Activity(
            kind: kind, text: text, category: "Focus",
            start: t0.addingTimeInterval(TimeInterval(minutes * 60)),
            end: t0.addingTimeInterval(TimeInterval((minutes + length) * 60)),
            eventID: eventID, sourceEventID: sourceEventID
        )
    }

    func build(_ events: [CalendarEventInfo] = [], _ activities: [Activity] = [], running: Activity? = nil) -> [CalendarBlock] {
        CalendarBlockBuilder.blocks(events: events, activities: activities, running: running, colors: ["c1": 0x112233, "c2": 0x445566], joins: false)
    }

    @Test func activityWithEventIDHidesThatEvent() {
        let blocks = build([event("e1")], [activity(eventID: "e1")])
        #expect(blocks.count == 1)
        if case .activity = blocks[0].source {} else { Issue.record("expected activity block") }
    }

    @Test func activityWithSourceEventIDKeepsTheEventInPlan() {
        let blocks = build([event("m1", length: 60)], [activity(at: 10, sourceEventID: "m1")])
        #expect(blocks.count == 2)
    }

    @Test func repeatingOccurrenceOnAnotherDayStillShows() {
        let other = event("m1", at: 24 * 60)
        let blocks = build([event("m1"), other], [activity(sourceEventID: "m1")])
        #expect(blocks.count == 3)
        #expect(blocks.contains { $0.source == .event(other) })
    }

    @Test func twinEventsAtDifferentTimesBothShow() {
        let blocks = build([event("t1", "Standup", calendar: "c1"), event("t2", "Standup ", at: 60, calendar: "c2")])
        #expect(blocks.count == 2)
    }

    @Test func stylesFollowTheKind() {
        let events = build([event("e1", calendar: "c2")])
        #expect(events[0].style == .event(colorHex: 0x445566))
        #expect(build([], [activity()])[0].style == .activity(category: "Focus"))
        #expect(build([], [activity(kind: .away)])[0].style == .away)
        #expect(build([], [activity(sourceEventID: "x")])[0].style == .joined(category: "Focus"))
    }

    @Test func allDayEventIsMarked() {
        #expect(build([event("e1", allDay: true)])[0].isAllDay)
    }

    @Test func runningActivityIsABlockWithRunningTrue() {
        let run = activity("Now", at: 5)
        let blocks = build([], [], running: run)
        #expect(blocks.count == 1)
        #expect(blocks[0].source == .activity(run, running: true))
    }

    @Test func runningActivityKeepsItsSourceEvent() {
        let run = activity("Now", sourceEventID: "e1")
        #expect(build([event("e1")], [], running: run).count == 2)
    }
}
