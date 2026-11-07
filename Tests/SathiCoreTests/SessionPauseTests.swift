import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Session pause")
struct SessionPauseTests {
    private let start = day(2026, 3, 4, 10)
    private var session: Session { Session(start: start, end: start.addingTimeInterval(600)) }

    @Test func runningSessionCountsFromStart() {
        let s = session
        #expect(!s.isPaused)
        #expect(s.elapsed(at: start.addingTimeInterval(100)) == 100)
        #expect(s.left(at: start.addingTimeInterval(100)) == 500)
    }

    @Test func elapsedStaysFrozenWhilePaused() {
        let s = session.paused(at: start.addingTimeInterval(120))
        #expect(s.isPaused)
        #expect(s.elapsed(at: start.addingTimeInterval(120)) == 120)
        #expect(s.elapsed(at: start.addingTimeInterval(9000)) == 120)
    }

    @Test func leftStaysFrozenWhilePaused() {
        let s = session.paused(at: start.addingTimeInterval(120))
        #expect(s.left(at: start.addingTimeInterval(120)) == 480)
        #expect(s.left(at: start.addingTimeInterval(9000)) == 480)
    }

    @Test func resumeShiftsStartAndEndByThePausedLength() {
        let paused = session.paused(at: start.addingTimeInterval(120))
        let back = paused.resumed(at: start.addingTimeInterval(420))
        #expect(back.start == start.addingTimeInterval(300))
        #expect(back.end == start.addingTimeInterval(900))
        #expect(back.pausedAt == nil)
        #expect(back.end.timeIntervalSince(back.start) == 600)
        #expect(back.elapsed(at: start.addingTimeInterval(420)) == 120)
    }

    @Test func pauseStoresAWholeSecond() {
        let s = session.paused(at: start.addingTimeInterval(120.734))
        #expect(s.pausedAt == start.addingTimeInterval(120))
    }

    @Test func pausingTwiceChangesNothing() {
        let once = session.paused(at: start.addingTimeInterval(120))
        #expect(once.paused(at: start.addingTimeInterval(500)) == once)
    }

    @Test func resumingARunningSessionChangesNothing() {
        #expect(session.resumed(at: start.addingTimeInterval(500)) == session)
    }
}
