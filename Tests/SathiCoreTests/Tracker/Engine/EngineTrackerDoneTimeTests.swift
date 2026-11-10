import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker Done time")
struct EngineTrackerDoneTimeTests {
    enum Interrupt: CaseIterable {
        case lock, shortcut, session, block, esc, trackerOff, idle
    }

    private func doneAtTen() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(9)) { $0.prefs.reading.sessionMinutes = 45 }
        h.start("Spec", minutes: 60)
        h.advance(minutes: 60)
        #expect(h.promptKind == .stillOnIt)
        h.engine.doneActivity()
        return h
    }

    private func interrupt(_ h: EngineHarness, _ i: Interrupt) {
        switch i {
        case .lock: h.engine.presenceChanged(.locked)
        case .shortcut: h.engine.trackerShortcutPressed()
        case .session: h.engine.startSession(.reading)
        case .block: h.startBlock("Plan", .minutes(30))
        case .esc: h.engine.closeTrackerPrompt()
        case .trackerOff: h.engine.data.prefs.tracker.isOn = false
        case .idle:
            h.presence.idleSeconds = 30 * 60
            h.advance(minutes: 25)
        }
    }

    @Test(arguments: Interrupt.allCases)
    func anInterruptAfterDoneSavesTheActivityUntilTheDoneTime(_ i: Interrupt) {
        let h = doneAtTen()
        h.advance(minutes: 5)
        interrupt(h, i)
        let work = h.saved.filter { $0.kind == .work }
        #expect(work.map(\.start) == [wed(9)])
        #expect(work.map(\.end) == [wed(10)])
    }

    @Test func theDoneTimeSurvivesARestart() {
        let h = doneAtTen()
        let again = EngineHarness.restartedTracker(from: h, at: wed(10, 5))
        again.engine.start()
        again.engine.presenceChanged(.locked)
        #expect(again.saved.filter { $0.kind == .work }.map(\.end) == [wed(10)])
    }

    @Test func aPickedSwitchTimeStillWinsOnStart() {
        let h = doneAtTen()
        h.clock.advance(minutes: 5)
        h.start("Next", at: wed(9, 40))
        #expect(h.saved.first?.end == wed(9, 40))
        #expect(h.running?.start == wed(9, 40))
    }

    @Test func skipWithNoPickedTimeEndsAtTheSkip() {
        let h = doneAtTen()
        h.clock.advance(minutes: 5)
        h.engine.skipTrackerPrompt()
        #expect(h.saved.first?.end == wed(10, 5))
    }
}
