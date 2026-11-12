import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker go away edges")
struct EngineTrackerGoAwayEdgeTests {
    private func goneAway(_ place: AwayPlace = .other, name: String? = "Sleep") -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.askEveryMinutes = 30 }
        h.start("Write spec", minutes: 30)
        h.clock.advance(minutes: 20)
        h.engine.goAway(place: place, name: name)
        return h
    }

    private func awayRows(_ h: EngineHarness) -> [Activity] { h.saved.filter { $0.kind == .away } }

    @Test func theGraceEndIsTheNextTrackerDeadlineThenItIsGone() {
        let h = goneAway()
        h.presence.idleSeconds = 30 * 60
        h.advance(minutes: 1.5)
        let since = wed(10, 20)
        #expect(h.engine.nextTickDelay() == since.addingTimeInterval(Timing.chosenAwayGrace).timeIntervalSince(h.clock.now))
        h.advance(minutes: 1)
        #expect(h.tracker.awaySince == since)
        #expect(h.engine.nextTickDelay() == Timing.idleTickMax)
    }

    @Test func goAwayWithTheTrackerOffDoesNothing() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.isOn = false }
        h.engine.goAway(place: .walk, name: nil)
        #expect(h.tracker.awaySince == nil)
        #expect(h.tracker.awayPlan == nil)
        #expect(h.saved.isEmpty)
    }

    @Test func aBreakDuringAChosenAwayEndsWithThePlannedPlace() {
        let h = goneAway()
        h.clock.advance(minutes: 5)
        h.engine.pause(hours: 0.5)
        #expect(h.tracker.awayCause == .onBreak)
        #expect(h.tracker.awayPlan == AwayPlan(place: .other, name: "Sleep"))
        h.advance(minutes: 30)
        #expect(awayRows(h).map(\.start) == [wed(10, 20)])
        #expect(awayRows(h).map(\.end) == [wed(10, 55)])
        #expect(awayRows(h).first?.awayPlace == .other)
        #expect(awayRows(h).first?.awayPlaceName == "Sleep")
        #expect(h.promptKind == .welcomeBack)
        #expect(h.tracker.awayPlan == nil)
    }

    @Test func turningTheTrackerOffClearsThePlan() {
        let h = goneAway()
        h.engine.data.prefs.tracker.isOn = false
        #expect(h.tracker.awaySince == nil)
        #expect(h.tracker.awayPlan == nil)
    }

    @Test func goAwayDuringAnotherAwayEndsItFirstAndStartsTheChosenOne() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: 10)
        h.engine.goAway(place: .lunch, name: nil)
        #expect(awayRows(h).map(\.start) == [wed(10)])
        #expect(awayRows(h).map(\.end) == [wed(10, 10)])
        #expect(awayRows(h).first?.awayPlace == nil)
        #expect(h.tracker.awaySince == wed(10, 10))
        #expect(h.tracker.awayCause == .chosen)
        #expect(h.tracker.awayPlan == AwayPlan(place: .lunch))
        #expect(h.promptKind == nil)
        h.clock.advance(minutes: 20)
        h.engine.presenceChanged(.unlocked)
        #expect(awayRows(h).map(\.start) == [wed(10), wed(10, 10)])
        #expect(awayRows(h).last?.awayPlace == .lunch)
    }
}
