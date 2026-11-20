import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine activity edit kind switch refusals")
struct EngineActivityEditKindRefusalTests {
    private let work = Activity(
        text: "Spec", category: "Coding", start: wed(9), end: wed(9, 30), calendarID: "work", eventID: "ev9"
    )
    private let away = Activity(kind: .away, text: "Away · Lunch", start: wed(12), end: wed(13), awayPlace: .lunch)

    private func harness(_ items: [Activity], configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness.tracker(at: wed(17), activities: items, configure: configure)
    }

    private func edit(
        _ a: Activity, kind: ActivityKind, text: String = "Spec", start: Date? = nil, end: Date? = nil,
        calendar: ActivityCalendarChoice = .none
    ) -> ActivityEdit {
        ActivityEdit(
            text: text, category: "Coding", start: start ?? a.start, end: end ?? a.end,
            awayPlace: kind == .away ? .lunch : nil, calendar: calendar, kind: kind
        )
    }

    private func saved(_ h: EngineHarness, _ a: Activity) -> Activity? { h.saved.first { $0.id == a.id } }

    @Test func aRowHeldByTheAwayUndoCannotSwitch() {
        let h = harness([work, away]) { $0.live.tracker.away.awayItems = [away.id] }
        #expect(h.engine.editActivity(away.id, edit(away, kind: .work, text: "Deep work")) == .awayUndo)
        #expect(saved(h, away) == away)
    }

    @Test func aLockedEventStopsWorkToAway() {
        let h = harness([work])
        h.calendarWriter.lockedEventIDs = ["ev9"]
        #expect(h.engine.editActivity(work.id, edit(work, kind: .away)) == .calendarUnchanged(work.id))
        #expect(saved(h, work) == work)
    }

    @Test func aFailedWriteOnAwayToWorkKeepsThePickForARetry() {
        let h = harness([away])
        h.calendarWriter.nextSaveResult = .failed
        let e = edit(away, kind: .work, text: "Sleep", calendar: .calendar("home"))
        #expect(h.engine.editActivity(away.id, e) == .calendarUnchanged(away.id))
        #expect(saved(h, away)?.kind == .work)
        #expect(saved(h, away)?.calendarID == "home")
        #expect(saved(h, away)?.eventID == nil)
    }

    @Test func awayToWorkWithNoTextIsRefused() {
        let h = harness([away])
        #expect(h.engine.editActivity(away.id, edit(away, kind: .work, text: "  ")) == .emptyText)
        #expect(saved(h, away) == away)
    }

    @Test func anOverlapIsRefusedBeforeTheEventIsDeleted() {
        let h = harness([work, away])
        #expect(h.engine.editActivity(work.id, edit(work, kind: .away, end: wed(12, 30))) == .overlap)
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(saved(h, work) == work)
    }

    @Test func aSwitchThatEndsInTheFutureIsRefused() {
        let h = harness([work])
        #expect(h.engine.editActivity(work.id, edit(work, kind: .away, end: wed(18))) == .inFuture)
        #expect(h.calendarWriter.deleted.isEmpty)
    }

    @Test func aTimeBlockRowCannotSwitch() {
        let block = Activity(kind: .timeBlock, text: "Deep work", start: wed(14), end: wed(15))
        let h = harness([block])
        #expect(h.engine.editActivity(block.id, edit(block, kind: .away)) == .notFound)
        #expect(saved(h, block) == block)
    }
}
