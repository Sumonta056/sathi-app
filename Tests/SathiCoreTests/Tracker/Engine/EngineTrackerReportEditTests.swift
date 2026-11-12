import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker report edits")
struct EngineTrackerReportEditTests {
    private let work = Activity(text: "Spec", category: "Coding", start: wed(9), end: wed(10))
    private let away = Activity(kind: .away, text: Copywriter.trackerAwayText(nil), start: wed(12), end: wed(13))
    private let block = Activity(kind: .timeBlock, text: "Deep work", start: wed(14), end: wed(15))

    private func harness() -> EngineHarness {
        EngineHarness.tracker(at: wed(17), activities: [work, away, block])
    }

    private func awayEdit(_ place: AwayPlace?, _ start: Date, _ end: Date) -> ActivityEdit {
        ActivityEdit(text: "", category: nil, start: start, end: end, awayPlace: place)
    }

    @Test func anAwayEditChangesThePlaceAndTimesAndTheTextFollows() {
        let h = harness()
        let r = h.engine.editActivity(away.id, awayEdit(.lunch, wed(12, 10), wed(12, 50)))
        #expect(r == .saved(away.id))
        let a = h.saved.first { $0.id == away.id }
        #expect(a?.awayPlace == .lunch)
        #expect(a?.text == Copywriter.trackerAwayText(.lunch))
        #expect(a?.kind == .away)
        #expect(a?.start == wed(12, 10))
        #expect(a?.end == wed(12, 50))
        #expect(a?.category == nil)
    }

    @Test func anAwayEditCanPickBreak() {
        let h = harness()
        h.engine.editActivity(away.id, awayEdit(.breakTime, wed(12), wed(13)))
        #expect(h.saved.first { $0.id == away.id }?.text == Copywriter.trackerAwayText(.breakTime))
    }

    @Test func anAwayEditThatOverlapsOrIsTooShortIsRefused() {
        let h = harness()
        #expect(h.engine.editActivity(away.id, awayEdit(.walk, wed(9, 30), wed(12, 30))) == .overlap)
        #expect(h.engine.editActivity(away.id, awayEdit(.walk, wed(12), wed(12, 0, s: 30))) == .tooShort)
        #expect(h.saved.first { $0.id == away.id }?.awayPlace == nil)
    }

    @Test func anAwayEditOrDeleteNeverTouchesTheCalendar() {
        let h = harness()
        h.engine.editActivity(away.id, awayEdit(.meeting, wed(12), wed(12, 30)))
        h.engine.deleteActivity(away.id)
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(!h.saved.contains { $0.id == away.id })
    }

    @Test func anEditThatCrossesMidnightIsRefused() {
        let h = harness()
        let edit = ActivityEdit(text: "Spec", category: nil, start: wed(23), end: day(2026, 3, 5, 0, 30))
        #expect(h.engine.editActivity(work.id, edit) == .crossesMidnight)
        #expect(h.saved.first { $0.id == work.id }?.start == wed(9))
    }

    @Test func anEditThatEndsAtMidnightIsSaved() {
        let h = EngineHarness.tracker(at: day(2026, 3, 5, 9), activities: [work, away, block])
        let edit = ActivityEdit(text: "Spec", category: nil, start: wed(23), end: day(2026, 3, 5))
        #expect(h.engine.editActivity(work.id, edit) == .saved(work.id))
    }

    @Test func aPastActivityThatCrossesMidnightIsRefused() {
        let h = EngineHarness.tracker(at: day(2026, 3, 5, 9))
        let edit = ActivityEdit(text: "Late", category: nil, start: wed(23, 30), end: day(2026, 3, 5, 0, 30))
        #expect(h.engine.addPastActivity(edit) == .crossesMidnight)
        #expect(h.saved.isEmpty)
    }

    @Test func aTimeBlockRowIsReadOnly() {
        let h = harness()
        let edit = ActivityEdit(text: "Other", category: "Coding", start: wed(14), end: wed(14, 30))
        #expect(h.engine.editActivity(block.id, edit) == .notFound)
        #expect(h.saved.first { $0.id == block.id } == block)
    }

    @Test func theRunningActivityCannotBeEdited() {
        let h = EngineHarness.tracker(at: wed(11))
        h.start("Now")
        h.clock.advance(minutes: 10)
        let id = h.engine.activityDay(DayKey(wed(11), calendar: .current)).running?.id
        let edit = ActivityEdit(text: "Now", category: nil, start: wed(11), end: wed(11, 5))
        #expect(h.engine.editActivity(id ?? ActivityID(), edit) == .notFound)
    }

    @Test func addPastRoundsToWholeSeconds() {
        let h = harness()
        let edit = ActivityEdit(
            text: "Mail",
            category: nil,
            start: wed(16, 0, s: 0).addingTimeInterval(0.6),
            end: wed(16, 20).addingTimeInterval(0.4)
        )
        guard case let .saved(id) = h.engine.addPastActivity(edit) else { Issue.record("not saved"); return }
        let a = h.saved.first { $0.id == id }
        #expect(a?.start == wed(16))
        #expect(a?.end == wed(16, 20))
    }

    @Test func addPastRefusesAnEndLaterThanNow() {
        let h = harness()
        let edit = ActivityEdit(text: "Later", category: nil, start: wed(16, 30), end: wed(17, 10))
        #expect(h.engine.addPastActivity(edit) == .inFuture)
        #expect(!h.saved.contains { $0.text == "Later" })
        #expect(h.engine.addPastActivity(ActivityEdit(text: "Now", category: nil, start: wed(16, 30), end: wed(17))) != .inFuture)
    }
}
