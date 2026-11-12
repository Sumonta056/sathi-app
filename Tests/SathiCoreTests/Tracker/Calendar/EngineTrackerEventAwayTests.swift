import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker calendar events while away")
struct EngineTrackerEventAwayTests {
    private func lockedAt(_ minute: Int, _ events: [CalendarEventInfo]) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents(events)
        h.start("Spec", minutes: 60)
        h.clock.advance(minutes: Double(minute))
        h.engine.presenceChanged(.locked)
        return h
    }

    @Test func theMacAwayAtTheEventStartLogsItWithNoQuestionAndShowsItInD() {
        let e = meeting(from: wed(10, 30), to: wed(11))
        let h = lockedAt(20, [e])
        h.advance(minutes: 10)
        #expect(h.notes.isEmpty)
        #expect(h.promptKind == nil)
        h.advance(minutes: 50)
        h.engine.presenceChanged(.unlocked)
        #expect(h.promptKind == .welcomeBack)
        let s = h.engine.trackerPromptState(.welcomeBack)
        #expect(s?.loggedWhileAway.map(\.text) == ["Standup"])
        #expect(s?.loggedWhileAway.first?.sourceEventID == "m1")
        #expect(h.eventItems.map(\.start) == [wed(10, 30)])
        #expect(h.eventItems.map(\.end) == [wed(11)])
        #expect(h.eventItems.first?.kind == .event)
        let away = h.saved.filter { $0.kind == .away }.map { [$0.start, $0.end] }
        #expect(away == [[wed(10, 20), wed(10, 30)], [wed(11), wed(11, 20)]])
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test func aReturnBeforeTheEventEndKeepsTheEventRunning() {
        let e = meeting(from: wed(10, 30), to: wed(11))
        let h = lockedAt(20, [e])
        h.advance(minutes: 20)
        h.engine.presenceChanged(.unlocked)
        #expect(h.running?.sourceEventID == "m1")
        #expect(h.running?.start == wed(10, 30))
        #expect(h.engine.trackerPromptState(.welcomeBack)?.loggedWhileAway.map(\.text) == ["Standup"])
        let away = h.saved.filter { $0.kind == .away }.map { [$0.start, $0.end] }
        #expect(away == [[wed(10, 20), wed(10, 30)]])
    }

    @Test func notAttendingARowInDTurnsItBackIntoAway() {
        let e = meeting(from: wed(10, 30), to: wed(11))
        let h = lockedAt(20, [e])
        h.advance(minutes: 60)
        h.engine.presenceChanged(.unlocked)
        h.engine.notAttendingEvent("m1")
        #expect(h.eventItems.isEmpty)
        #expect(h.engine.trackerPromptState(.welcomeBack)?.loggedWhileAway.isEmpty == true)
        let away = h.saved.filter { $0.kind == .away }
        #expect(away.reduce(0) { $0 + $1.length } == 60 * 60)
        h.engine.setAwayPlace(.lunch)
        #expect(h.saved.filter { $0.kind == .away }.allSatisfy { $0.awayPlace == .lunch })
    }

    @Test func overlappingEventsWhileAwayKeepTheFirst() {
        let h = lockedAt(20, [
            meeting("a", "Planning", from: wed(10, 30), to: wed(11)),
            meeting("b", "Interview", from: wed(10, 40), to: wed(11, 10))
        ])
        h.advance(minutes: 60)
        h.engine.presenceChanged(.unlocked)
        #expect(h.eventItems.map(\.text) == ["Planning"])
    }

    @Test func nothingIsLoggedWhenReadingIsOff() {
        let h = lockedAt(20, [meeting(from: wed(10, 30), to: wed(11))])
        h.engine.data.prefs.tracker.readsEvents = false
        h.advance(minutes: 60)
        h.engine.presenceChanged(.unlocked)
        #expect(h.eventItems.isEmpty)
    }
}
