import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine one lock")
struct EngineOneLockTests {
    private func harness(_ on: Set<HabitID> = Set(HabitID.allCases), strict: Bool = false) -> EngineHarness {
        EngineHarness(at: day(2026, 3, 4, 15)) {
            $0.prefs.water.enabled = on.contains(.water)
            $0.prefs.reading.enabled = on.contains(.reading)
            $0.prefs.meditation.enabled = on.contains(.meditation)
            $0.prefs.gym.enabled = on.contains(.gym)
            $0.live.lastWaterDone = day(2026, 3, 4, 14, 59)
            if strict {
                $0.prefs.water.strictness = .strict
                $0.prefs.reading.strictness = .strict
                $0.prefs.meditation.strictness = .strict
                $0.prefs.gym.strictness = .strict
            }
        }
    }

    @Test(arguments: HabitID.allCases)
    func aSnoozeChangesOnlyThatHabit(_ id: HabitID) {
        let h = harness()
        for other in HabitID.allCases {
            h.showReminder(other)
        }
        for other in HabitID.allCases {
            #expect(h.engine.phase(other) == .bubble(.nudge))
        }
        let before = Dictionary(uniqueKeysWithValues: HabitID.allCases.map { ($0, h.engine.state($0)) })
        h.engine.snooze(id)
        #expect(h.engine.state(id).snoozes == 1)
        #expect(h.history.appended.last == .snooze(id, at: h.clock.now))
        for other in HabitID.allCases where other != id {
            #expect(h.engine.state(other) == before[other])
            #expect(h.engine.phase(other) == .bubble(.nudge))
        }
    }

    @Test(arguments: [(HabitID.water, HabitID.reading), (.water, .gym), (.reading, .gym), (.meditation, .reading)])
    func secondStrictHabitShowsANudgyBubbleThenLocksLater(_ first: HabitID, _ second: HabitID) {
        let h = harness([first, second], strict: true)
        h.showReminder(first)
        h.showReminder(second)
        for _ in 0 ..< 2 {
            h.engine.snooze(first)
            h.engine.snooze(second)
            h.advance(minutes: Double(h.engine.data.prefs.general.snoozeMinutes))
        }
        let locked = [first, second].filter { h.engine.phase($0) == .lock }
        #expect(locked.count == 1)
        guard let lockedID = locked.first else { return }
        let waiting = lockedID == first ? second : first
        #expect(h.engine.phase(waiting) == .bubble(.persist))
        #expect(!h.presenter.calls.contains(.showLock(waiting)))
        h.engine.emergencySkip(lockedID)
        h.engine.snooze(waiting)
        h.advance(minutes: Double(h.engine.data.prefs.general.snoozeMinutes))
        #expect(h.engine.phase(waiting) == .lock)
        #expect(h.presenter.calls.last == .showLock(waiting))
    }
}
