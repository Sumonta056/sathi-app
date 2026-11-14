import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Calendar page after a manual merge")
struct CalendarPageMergeTests {
    private let a = Activity(text: "Code", category: "Work", start: wed(10), end: wed(10, 30), calendarID: "work", eventID: "e1")
    private let b = Activity(text: "Mail", category: "Work", start: wed(10, 40), end: wed(11), calendarID: "work", eventID: "e2")

    private func harness() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(13), activities: [a, b])
        h.calendarWriter.mirrorsWrites = true
        h.calendarWriter.eventsValue = [
            meeting("e1", "Code", from: wed(10), to: wed(10, 30)),
            meeting("e2", "Mail", from: wed(10, 40), to: wed(11))
        ]
        h.calendarWriter.nextSaveResult = .saved(eventID: "e9")
        h.engine.calendarPageOpened()
        return h
    }

    private func activityBlocks(_ h: EngineHarness) -> [CalendarBlock] {
        h.pageDay.blocks.filter { if case .activity = $0.source { true } else { false } }
    }

    private func outlines(_ h: EngineHarness) -> [String] {
        h.pageDay.blocks.compactMap { if case let .event(e) = $0.source { e.id } else { nil } }
    }

    @Test func aMergeLeavesOneActivityBlockAndNoOutline() {
        let h = harness()
        #expect(activityBlocks(h).count == 2)
        #expect(h.engine.mergeActivities([a.id, b.id]) == .merged(a.id))
        let blocks = activityBlocks(h)
        #expect(blocks.count == 1)
        #expect(blocks.first?.interval == DateInterval(start: wed(10), end: wed(11)))
        #expect(outlines(h).isEmpty)
    }

    @Test func undoShowsTwoBlocksAndNoOutlineForTheEventMadeAgain() {
        let h = harness()
        #expect(h.engine.mergeActivities([a.id, b.id]) == .merged(a.id))
        #expect(h.engine.undoMerge() == .restored)
        #expect(activityBlocks(h).map(\.title) == ["Code", "Mail"])
        #expect(h.saved.map(\.eventID) == ["e1", "e9"])
        #expect(h.calendarWriter.eventsValue.map(\.id).sorted() == ["e1", "e9"])
        #expect(outlines(h).isEmpty)
    }
}
