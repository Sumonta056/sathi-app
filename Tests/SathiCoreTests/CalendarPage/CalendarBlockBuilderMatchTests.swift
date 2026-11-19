import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockBuilder copies and title join")
struct CalendarBlockBuilderMatchTests {
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func event(
        _ id: String,
        _ title: String = "Standup",
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

    func activity(_ text: String, kind: ActivityKind = .work, at minutes: Int = 0, length: Int = 30) -> Activity {
        Activity(
            kind: kind, text: text, category: "Focus",
            start: t0.addingTimeInterval(TimeInterval(minutes * 60)),
            end: t0.addingTimeInterval(TimeInterval((minutes + length) * 60))
        )
    }

    func build(_ events: [CalendarEventInfo] = [], _ activities: [Activity] = [], running: Activity? = nil) -> [CalendarBlock] {
        CalendarBlockBuilder.blocks(
            events: events, activities: activities, running: running,
            colors: ["c1": 0x112233, "c2": 0x445566, "c3": 0x778899], joins: false
        )
    }

    func eventBlocks(_ blocks: [CalendarBlock]) -> [CalendarBlock] {
        blocks.filter { if case .event = $0.source { true } else { false } }
    }

    func activityBlocks(_ blocks: [CalendarBlock]) -> [CalendarBlock] {
        blocks.filter { if case .activity = $0.source { true } else { false } }
    }

    @Test func blockHasOneCopyByDefault() {
        let blocks = build([event("e1")])
        #expect(blocks.map(\.copies) == [1])
    }

    @Test func sameEventInTwoCalendarsIsOneBlockWithTwoCopies() {
        let first = event("e1", "Standup", calendar: "c1")
        let blocks = build([first, event("e2", " Standup ", calendar: "c2")])
        #expect(blocks.count == 1)
        #expect(blocks[0].copies == 2)
        #expect(blocks[0].source == .event(first))
        #expect(blocks[0].style == .event(colorHex: 0x112233))
    }

    @Test func sameEventInThreeCalendarsCountsThree() {
        let blocks = build([event("e1", calendar: "c1"), event("e2", calendar: "c2"), event("e3", calendar: "c3")])
        #expect(blocks.count == 1)
        #expect(blocks[0].copies == 3)
    }

    @Test func differentEndIsTwoBlocks() {
        let blocks = build([event("e1", calendar: "c1"), event("e2", length: 45, calendar: "c2")])
        #expect(blocks.count == 2)
        #expect(blocks.allSatisfy { $0.copies == 1 })
    }

    @Test func differentStartIsTwoBlocks() {
        let blocks = build([event("e1", calendar: "c1"), event("e2", at: 5, length: 25, calendar: "c2")])
        #expect(blocks.count == 2)
    }

    @Test func differentTitleIsTwoBlocks() {
        let blocks = build([event("e1", "Standup", calendar: "c1"), event("e2", "Retro", calendar: "c2")])
        #expect(blocks.count == 2)
    }

    @Test func allDayEventsAreNotMerged() {
        let blocks = build([event("e1", allDay: true, calendar: "c1"), event("e2", allDay: true, calendar: "c2")])
        #expect(blocks.count == 2)
        #expect(blocks.allSatisfy { $0.copies == 1 })
    }

    @Test func activityWithTheEventTitleKeepsItAndIsJoined() {
        let blocks = build([event("e1", "Standup")], [activity("standup ", at: 10)])
        #expect(eventBlocks(blocks).count == 1)
        #expect(blocks.count == 2)
        #expect(activityBlocks(blocks).map(\.style) == [.joined(category: "Focus")])
    }

    @Test func titleJoinTrimsTheEventTitleToo() {
        let blocks = build([event("e1", "  STANDUP\n")], [activity("Standup", at: 20)])
        #expect(eventBlocks(blocks).count == 1)
        #expect(activityBlocks(blocks).map(\.style) == [.joined(category: "Focus")])
    }

    @Test func sameTitleWithoutOverlapShowsBoth() {
        let blocks = build([event("e1", "Standup")], [activity("Standup", at: 60)])
        #expect(eventBlocks(blocks).count == 1)
        #expect(blocks.count == 2)
        #expect(blocks.first { if case .activity = $0.source { true } else { false } }?.style == .activity(category: "Focus"))
    }

    @Test func touchingSameTitleIsNoOverlap() {
        let blocks = build([event("e1", "Standup")], [activity("Standup", at: 30)])
        #expect(eventBlocks(blocks).count == 1)
    }

    @Test func otherTitleOverlappingShowsBoth() {
        let blocks = build([event("e1", "Standup")], [activity("Coding", at: 10)])
        #expect(eventBlocks(blocks).count == 1)
        #expect(blocks.count == 2)
    }

    @Test func awayWithTheEventTitleNeverHidesIt() {
        let blocks = build([event("e1", "Standup")], [activity("Standup", kind: .away, at: 10)])
        #expect(eventBlocks(blocks).count == 1)
        #expect(blocks.count == 2)
    }

    @Test func titleJoinKeepsTheCopiesAsOneCard() {
        let blocks = build([event("e1", calendar: "c1"), event("e2", calendar: "c2")], [activity("Standup", at: 5)])
        #expect(eventBlocks(blocks).map(\.copies) == [2])
    }

    @Test func twinsInOneCalendarStayTwoBlocks() {
        let blocks = build([event("e1", calendar: "c1"), event("e2", calendar: "c1")])
        #expect(blocks.count == 2)
        #expect(blocks.map(\.copies) == [1, 1])
    }

    @Test func shownCopyIsTheLowestCalendarID() {
        let low = event("e1", calendar: "c1")
        let blocks = build([event("e2", calendar: "c2"), low])
        #expect(blocks.map(\.source) == [.event(low)])
    }

    @Test func runningActivityWithTheEventTitleKeepsIt() {
        let blocks = build([event("e1")], running: activity("Standup", at: 5))
        #expect(eventBlocks(blocks).count == 1)
        #expect(activityBlocks(blocks).map(\.style) == [.joined(category: "Focus")])
    }

    @Test func weekGroupIsJoinedWhenALaterRowMatches() {
        let rows = [activity("Standup", at: 0, length: 30), activity("Standup", at: 32, length: 58)]
        let blocks = CalendarBlockBuilder.blocks(
            events: [event("e1", at: 60, length: 15)], activities: rows, running: nil, colors: ["c1": 0x112233], joins: true
        )
        #expect(activityBlocks(blocks).map(\.style) == [.joined(category: "Focus")])
    }
}
