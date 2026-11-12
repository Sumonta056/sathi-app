import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker go away")
struct EngineTrackerGoAwayTests {
    private func goneAway(_ place: AwayPlace = .other, name: String? = "Sleep") -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 30 }
        h.start("Write spec", minutes: 30)
        h.clock.advance(minutes: 20)
        h.engine.goAway(place: place, name: name)
        return h
    }

    private func awayRows(_ h: EngineHarness) -> [Activity] { h.saved.filter { $0.kind == .away } }

    private func welcome(_ h: EngineHarness) -> AwaySpan? { h.engine.trackerPromptState(.welcomeBack)?.away }

    @Test func goAwayEndsTheRunningActivityNowAndStartsAChosenAway() {
        let h = goneAway()
        #expect(h.running == nil)
        #expect(h.saved.map(\.kind) == [.work])
        #expect(h.saved.first?.end == wed(10, 20))
        #expect(h.tracker.awaySince == wed(10, 20))
        #expect(h.tracker.awayCause == .chosen)
        #expect(h.tracker.awayPlan == AwayPlan(place: .other, name: "Sleep"))
        #expect(h.promptKind == nil)
    }

    @Test func inputBeforeTheGraceKeepsTheAway() {
        let h = goneAway()
        h.presence.idleSeconds = 0
        h.advance(minutes: 1)
        #expect(h.tracker.awaySince == wed(10, 20))
        #expect(awayRows(h).isEmpty)
        #expect(h.promptKind == nil)
    }

    @Test func inputAfterTheGraceReturnsAndStoresThePlace() {
        let h = goneAway()
        h.presence.idleSeconds = 0
        h.advance(minutes: 30)
        #expect(h.tracker.awaySince == nil)
        #expect(h.tracker.awayPlan == nil)
        #expect(awayRows(h).map(\.start) == [wed(10, 20)])
        #expect(awayRows(h).map(\.end) == [wed(10, 50)])
        #expect(awayRows(h).first?.awayPlace == .other)
        #expect(awayRows(h).first?.awayPlaceName == "Sleep")
        #expect(awayRows(h).first?.text == Copywriter.trackerAwayText(.other, name: "Sleep"))
        #expect(h.promptKind == .welcomeBack)
        #expect(welcome(h)?.place == .other)
        #expect(welcome(h)?.placeName == "Sleep")
        #expect(welcome(h)?.cause == .chosen)
    }

    @Test func oldInputAfterTheGraceStillKeepsTheAway() {
        let h = goneAway()
        h.presence.idleSeconds = 29 * 60
        h.advance(minutes: 30)
        #expect(h.tracker.awaySince == wed(10, 20))
        #expect(awayRows(h).isEmpty)
    }

    @Test func lockThenUnlockStoresThePlannedPlace() {
        let h = goneAway(.lunch, name: nil)
        h.clock.advance(minutes: 5)
        h.engine.presenceChanged(.locked)
        #expect(h.tracker.awayCause == .locked)
        #expect(h.tracker.awayPlan == AwayPlan(place: .lunch))
        h.clock.advance(minutes: 25)
        h.engine.presenceChanged(.unlocked)
        #expect(awayRows(h).map(\.start) == [wed(10, 20)])
        #expect(awayRows(h).first?.awayPlace == .lunch)
        #expect(awayRows(h).first?.text == Copywriter.trackerAwayText(.lunch))
        #expect(welcome(h)?.place == .lunch)
        #expect(h.tracker.awayPlan == nil)
    }

    @Test func sleepThenWakeStoresThePlannedPlace() {
        let h = goneAway()
        h.engine.presenceChanged(.sleep)
        h.clock.advance(minutes: 40)
        h.engine.presenceChanged(.wake)
        #expect(awayRows(h).map(\.end) == [wed(11)])
        #expect(awayRows(h).first?.awayPlaceName == "Sleep")
        #expect(h.promptKind == .welcomeBack)
        #expect(welcome(h)?.placeName == "Sleep")
    }

    @Test func theWhatNowPromptActionGoesAway() {
        let h = EngineHarness.tracker(at: wed(10))
        #expect(h.promptKind == .whatNow)
        h.engine.trackerPromptState(.whatNow)?.actions.goAway(.walk, nil)
        #expect(h.tracker.awayCause == .chosen)
        #expect(h.tracker.awayPlan == AwayPlan(place: .walk))
        #expect(h.promptKind == nil)
    }

    @Test func aRestartDuringAChosenAwayKeepsThePlace() {
        let old = goneAway(.meeting, name: nil)
        let h = EngineHarness.restartedTracker(from: old, at: wed(11))
        h.engine.start()
        #expect(awayRows(h).first?.awayPlace == .meeting)
        #expect(awayRows(h).first?.end == wed(11))
    }

    @Test func savedLiveStateWithoutAPlanDecodesAndAPlanRoundTrips() throws {
        let old = try JSONDecoder().decode(TrackerLiveState.self, from: Data(#"{"awayCause":"chosen"}"#.utf8))
        #expect(old.awayPlan == nil)
        #expect(old.awayCause == .chosen)
        var live = TrackerLiveState()
        live.awayPlan = AwayPlan(place: .other, name: "Sleep")
        let back = try JSONDecoder().decode(TrackerLiveState.self, from: JSONEncoder().encode(live))
        #expect(back.awayPlan == live.awayPlan)
        let bad = try JSONDecoder().decode(TrackerLiveState.self, from: Data(#"{"awayPlan":{"place":"moon"}}"#.utf8))
        #expect(bad.awayPlan == nil)
    }
}
