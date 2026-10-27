import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
func onlyHabit(_ id: HabitID, _ strictness: Strictness, at start: Date = day(2026, 3, 4, 15)) -> EngineHarness {
    EngineHarness(at: start) {
        $0.prefs.water.enabled = false
        $0.prefs.reading.enabled = false
        $0.prefs.meditation.enabled = false
        $0.prefs.gym.enabled = false
        switch id {
        case .water: ($0.prefs.water.enabled, $0.prefs.water.strictness) = (true, strictness)
        case .reading: ($0.prefs.reading.enabled, $0.prefs.reading.strictness) = (true, strictness)
        case .meditation: ($0.prefs.meditation.enabled, $0.prefs.meditation.strictness) = (true, strictness)
        case .gym: ($0.prefs.gym.enabled, $0.prefs.gym.strictness) = (true, strictness)
        }
    }
}

@MainActor
func snoozeAndWait(_ h: EngineHarness, _ id: HabitID) {
    h.engine.snooze(id)
    h.advance(minutes: Double(h.engine.data.prefs.general.snoozeMinutes))
}

@MainActor
func reachLock(_ id: HabitID) -> EngineHarness {
    let h = onlyHabit(id, .strict)
    h.showReminder(id)
    snoozeAndWait(h, id)
    snoozeAndWait(h, id)
    return h
}

@MainActor
@Suite("Strictness for every habit")
struct StrictnessAllHabitsTests {
    private static func expected(_ s: Strictness) -> [Phase] {
        switch s {
        case .friendly: return [.bubble(.nudge), .bubble(.nudge), .bubble(.nudge)]
        case .persistent: return [.bubble(.nudge), .bubble(.persist), .bubble(.persist)]
        case .strict: return [.bubble(.nudge), .bubble(.persist), .lock]
        }
    }

    @Test(arguments: HabitID.allCases, Strictness.allCases)
    func twoSnoozesFollowTheLevel(_ id: HabitID, _ s: Strictness) {
        let h = onlyHabit(id, s)
        h.showReminder(id)
        var seen = [h.engine.phase(id)]
        snoozeAndWait(h, id)
        seen.append(h.engine.phase(id))
        snoozeAndWait(h, id)
        seen.append(h.engine.phase(id))
        #expect(seen == Self.expected(s))
        #expect(h.engine.state(id).snoozes == 2)
        #expect(h.presenter.calls.contains(.showLock(id)) == (s == .strict))
    }

    @Test(arguments: HabitID.allCases, Strictness.allCases)
    func storedStrictnessIsReturnedAsIs(_ id: HabitID, _ s: Strictness) {
        var p = Prefs()
        p.water.strictness = s
        p.reading.strictness = s
        p.meditation.strictness = s
        p.gym.strictness = s
        #expect(p.strictness(id) == s)
    }

    @Test func storedStrictReadingAndGymDecodeAsStrict() throws {
        let json = #"{"reading":{"strictness":"strict","showsCloseButton":true},"gym":{"strictness":"strict","showsCloseButton":true}}"#
        let p = try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
        #expect(p.reading.strictness == .strict)
        #expect(p.gym.strictness == .strict)
        #expect(p.strictness(.reading) == .strict)
        #expect(p.strictness(.gym) == .strict)
    }

    @Test(arguments: [HabitID.reading, .gym])
    func lockIsNextAfterOneSnoozeAtStrict(_ id: HabitID) {
        let h = onlyHabit(id, .strict)
        h.showReminder(id)
        #expect(!h.engine.lockIsNext(id))
        snoozeAndWait(h, id)
        #expect(h.engine.lockIsNext(id))
    }

    @Test(arguments: [HabitID.reading, .gym])
    func lockConfirmedStartsTheSession(_ id: HabitID) {
        let h = reachLock(id)
        #expect(h.engine.phase(id) == .lock)
        h.engine.lockConfirmed(id)
        #expect(h.engine.phase(id) == .session)
        #expect(h.engine.session(id) != nil)
        #expect(h.presenter.calls.contains(.closeLock))
    }

    @Test(arguments: [HabitID.reading, .gym])
    func emergencySkipClosesTheLockAndRecordsASkip(_ id: HabitID) {
        let h = reachLock(id)
        #expect(h.engine.phase(id) == .lock)
        h.engine.emergencySkip(id)
        #expect(h.engine.phase(id) == .idle)
        #expect(h.presenter.calls.last == .closeLock)
        #expect(h.history.appended.last == .skip(id, at: h.clock.now))
    }
}
