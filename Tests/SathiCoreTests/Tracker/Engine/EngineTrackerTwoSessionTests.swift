import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker two sessions at once")
struct EngineTrackerTwoSessionTests {
    private func twoSessions() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10)) {
            $0.prefs.reading.sessionMinutes = 45
            $0.prefs.meditation.sessionMinutes = 20
        }
        h.start("Spec", minutes: 60)
        h.clock.advance(minutes: 5)
        h.engine.startSession(.reading)
        h.clock.advance(minutes: 5)
        h.engine.startMeditation()
        h.clock.advance(minutes: 5)
        return h
    }

    @Test func theFirstSessionEndingKeepsTheContinueForTheLastOne() {
        let h = twoSessions()
        h.engine.stopSession(.reading)
        #expect(h.running?.category == "Meditation")
        #expect(h.promptKind == nil)
        h.clock.advance(minutes: 5)
        h.engine.stopSession(.meditation)
        #expect(h.engine.trackerPromptState(.whatNow)?.resume?.text == "Spec")
    }

    @Test func theLatestSessionEndingStartsTheBuddyActivityOfTheOneStillRunning() {
        let h = twoSessions()
        h.engine.stopSession(.meditation)
        #expect(h.running?.category == "Reading")
        #expect(h.running?.start == wed(10, 15))
        #expect(h.promptKind == nil)
        h.clock.advance(minutes: 10)
        h.engine.stopSession(.reading)
        let buddies = h.saved.filter { $0.kind == .buddy }
        #expect(buddies.map(\.category) == ["Reading", "Meditation", "Reading"])
        #expect(buddies.map(\.end) == [wed(10, 10), wed(10, 15), wed(10, 25)])
        #expect(h.engine.trackerPromptState(.whatNow)?.resume?.text == "Spec")
    }
}
