import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker event runs through Away")
struct EngineTrackerEventKeepTests {
    private func inMeeting() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(9, 55))
        h.useEvents([meeting(from: wed(10), to: wed(11))])
        h.start("Spec", minutes: 60)
        h.advance(minutes: 5)
        #expect(h.running?.sourceEventID == "m1")
        return h
    }

    private func awaySpans(_ h: EngineHarness) -> [[Date]] {
        h.saved.filter { $0.kind == .away }.map { [$0.start, $0.end] }
    }

    @Test func idleDuringTheMeetingKeepsTheEventRunningAndAReturnBeforeTheEndShowsNoD() {
        let h = inMeeting()
        h.presence.idleSeconds = 30 * 60
        h.advance(minutes: 30)
        #expect(h.store.live.tracker.awaySince == wed(10))
        #expect(h.running?.sourceEventID == "m1")
        h.clock.advance(minutes: 10)
        h.presence.idleSeconds = 0
        h.engine.tick()
        #expect(h.store.live.tracker.awaySince == nil)
        #expect(h.running?.sourceEventID == "m1")
        #expect(h.running?.start == wed(10))
        #expect(!h.trackerShows.contains(.welcomeBack))
        #expect(awaySpans(h).isEmpty)
    }

    @Test func theEventEndPassingWhileAwaySavesTheEventUntilItsEndAndAwayCoversTheRest() {
        let h = inMeeting()
        h.clock.advance(minutes: 10)
        h.engine.presenceChanged(.locked)
        #expect(h.running?.sourceEventID == "m1")
        h.advance(minutes: 50)
        h.advance(minutes: 20)
        h.engine.presenceChanged(.unlocked)
        #expect(h.running == nil)
        #expect(h.eventItems.map { [$0.start, $0.end] } == [[wed(10), wed(11)]])
        #expect(awaySpans(h) == [[wed(11), wed(11, 20)]])
        #expect(h.promptKind == .welcomeBack)
    }

    @Test func aRestartWhileAwayInAMeetingStillCutsAwayAroundTheEvent() {
        let h = inMeeting()
        h.clock.advance(minutes: 10)
        h.engine.presenceChanged(.locked)
        let again = EngineHarness.restartedTracker(from: h, at: wed(11, 30))
        again.engine.start()
        #expect(again.eventItems.map { [$0.start, $0.end] } == [[wed(10), wed(11)]])
        #expect(awaySpans(again) == [[wed(11), wed(11, 30)]])
    }

    @Test func aBreakStillEndsTheEventAtTheBreakStart() {
        let h = inMeeting()
        h.clock.advance(minutes: 10)
        h.engine.pause(hours: 0.5)
        #expect(h.running == nil)
        #expect(h.eventItems.map(\.end) == [wed(10, 10)])
    }
}
