import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Breath cues")
struct BreathCuesTests {
    private let start = day(2026, 3, 4, 10)

    private func session(minutes: Double = 2) -> Session {
        Session(start: start, end: start.addingTimeInterval(minutes * Timing.minute))
    }

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    @Test func atTheStartTheInhaleCueIsDue() {
        let due = BreathCues.dueCue(.calm, session: session(), now: start, mark: nil)
        #expect(due?.cue == .inhale)
        #expect(due?.boundary == start)
    }

    @Test func calmNextBoundaryIsTheEndOfTheInhale() {
        #expect(BreathCues.nextBoundary(.calm, session: session(), now: at(3.5)) == at(4))
    }

    @Test func calmExhaleIsDueAtFourSeconds() {
        let due = BreathCues.dueCue(.calm, session: session(), now: at(4), mark: start)
        #expect(due?.cue == .exhale)
        #expect(due?.boundary == at(4))
    }

    @Test func theSameMarkIsNotDueAgain() {
        #expect(BreathCues.dueCue(.calm, session: session(), now: at(4.5), mark: at(4)) == nil)
    }

    @Test func aLateCueIsSkipped() {
        #expect(BreathCues.dueCue(.calm, session: session(), now: at(5.5), mark: nil) == nil)
    }

    @Test func aPausedSessionHasNoCueAndNoBoundary() {
        var s = session()
        s.pausedAt = at(4)
        #expect(BreathCues.dueCue(.calm, session: s, now: at(4), mark: nil) == nil)
        #expect(BreathCues.nextBoundary(.calm, session: s, now: at(4)) == nil)
    }

    @Test func noBoundaryAtOrAfterTheEnd() {
        let s = session(minutes: 1)
        #expect(BreathCues.nextBoundary(.calm, session: s, now: at(55)) == nil)
        #expect(BreathCues.nextBoundary(.calm, session: s, now: at(61)) == nil)
        #expect(BreathCues.dueCue(.calm, session: s, now: at(60), mark: at(50)) == nil)
    }

    @Test func boxCuesEveryPhase() {
        let s = session()
        #expect(BreathCues.dueCue(.box, session: s, now: at(4), mark: start)?.cue == .hold)
        #expect(BreathCues.dueCue(.box, session: s, now: at(8.2), mark: at(4))?.cue == .exhale)
        #expect(BreathCues.dueCue(.box, session: s, now: at(12), mark: at(8))?.cue == .rest)
        #expect(BreathCues.dueCue(.box, session: s, now: at(16), mark: at(12))?.cue == .inhale)
    }

    @Test func dueMinuteAtSixtySeconds() {
        #expect(BreathCues.dueMinute(session: session(), now: at(60), mark: nil) == at(60))
        #expect(BreathCues.dueMinute(session: session(), now: at(60.5), mark: at(60)) == nil)
    }

    @Test func noMinuteAtThirtySeconds() {
        #expect(BreathCues.dueMinute(session: session(), now: at(30), mark: nil) == nil)
    }

    @Test func noMinuteAtTheEndOfAOneMinuteSession() {
        let s = session(minutes: 1)
        #expect(BreathCues.dueMinute(session: s, now: at(60), mark: nil) == nil)
        #expect(BreathCues.nextMinute(session: s, now: at(30)) == nil)
    }

    @Test func nextMinuteIsTheNextFullMinute() {
        #expect(BreathCues.nextMinute(session: session(), now: at(30)) == at(60))
        #expect(BreathCues.nextMinute(session: session(), now: at(60)) == nil)
        #expect(BreathCues.nextMinute(session: session(minutes: 5), now: at(60)) == at(120))
    }
}
