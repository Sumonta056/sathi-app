import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
private func doneEvents(_ h: EngineHarness) -> [HistoryEvent] {
    h.history.appended.filter { $0.kind == .done }
}

@MainActor
private func deadline(_ h: EngineHarness, _ id: HabitID) -> Date? {
    guard case let .bubble(_, _, d) = h.engine.activities[id] else { return nil }
    return d
}

@MainActor
@Suite("Engine gym")
struct EngineGymTests {
    private func harness(at start: Date = day(2026, 3, 4, 10), configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.gym.enabled = true
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            configure(&$0)
        }
    }

    private func atTen(configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        let h = harness(at: day(2026, 3, 4, 9), configure: configure)
        h.advance(minutes: 60)
        return h
    }

    @Test func firstReminderShowsAtTenInTheCorner() {
        let h = harness(at: day(2026, 3, 4, 9))
        h.advance(minutes: 60)
        #expect(h.presenter.calls.contains(.showBubble(.gym, .nudge)))
        #expect(h.engine.usesCorner(.gym))
    }

    @Test func firstWorkoutOfTheDayIsWorkoutOne() {
        let h = atTen()
        #expect(h.engine.gymWorkout.name == "Neck and shoulder stretch")
    }

    @Test func nextIdeaShowsTheNextWorkoutAndWrapsAfterFour() {
        let h = atTen()
        let before = h.history.appended
        h.engine.nextGymIdea()
        #expect(h.engine.gymWorkout.name == "Short walk")
        for _ in 0 ..< 4 {
            h.engine.nextGymIdea()
        }
        #expect(h.engine.gymWorkout.name == "Short walk")
        #expect(h.history.appended == before)
    }

    @Test func nextIdeaKeepsTheIgnoreDeadline() {
        let h = atTen()
        let before = deadline(h, .gym)
        #expect(before != nil)
        h.engine.nextGymIdea()
        #expect(deadline(h, .gym) == before)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
    }

    @Test func startRunsTheShownWorkout() {
        let h = atTen()
        h.engine.nextGymIdea()
        h.engine.nextGymIdea()
        h.engine.startSession(.gym)
        let s = h.engine.session(.gym)
        #expect(s?.workout == 2)
        #expect(s.map { $0.end.timeIntervalSince($0.start) } == 3 * Timing.minute)
        #expect(h.engine.gymWorkout.name == "10 squats")
    }

    @Test func doneEarlyCountsOneWorkout() {
        let h = atTen()
        h.engine.startSession(.gym)
        h.advance(minutes: 1)
        h.engine.finishSession(.gym)
        #expect(h.history.appended.last == .done(.gym, 1, at: day(2026, 3, 4, 10, 1)))
        #expect(h.engine.celebration.amount == 1)
        #expect(h.engine.state(.gym).nextDue == day(2026, 3, 4, 11, 1))
    }

    @Test func timerEndCountsOneWorkout() {
        let h = atTen()
        h.engine.startSession(.gym)
        h.advance(minutes: 5)
        #expect(h.history.appended.last == .done(.gym, 1, at: day(2026, 3, 4, 10, 5)))
        #expect(h.engine.celebration.amount == 1)
        #expect(h.engine.state(.gym).nextDue == day(2026, 3, 4, 11, 5))
    }

    @Test func stopDoesNotCount() {
        let h = atTen()
        h.engine.startSession(.gym)
        h.engine.stopSession(.gym)
        #expect(doneEvents(h).isEmpty)
    }

    @Test func secondReminderAfterOneDoneShowsWorkoutTwo() {
        let h = atTen()
        h.engine.nextGymIdea()
        h.engine.startSession(.gym)
        h.advance(minutes: 5)
        h.engine.endCelebrate()
        h.advance(minutes: 60)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        #expect(h.engine.gymWorkout.name == "Short walk")
        #expect(h.engine.gymIdea == 0)
    }

    @Test func closeIsNotNowAndComesBackNextInterval() {
        let h = atTen()
        h.engine.notNow(.gym)
        #expect(h.history.appended.last == .snooze(.gym, at: day(2026, 3, 4, 10)))
        #expect(h.engine.state(.gym).nextDue == day(2026, 3, 4, 11))
        #expect(h.engine.state(.gym).snoozes == 0)
        #expect(h.engine.state(.gym).snoozedUntil == nil)
        #expect(h.engine.activities[.gym] == nil)
        #expect(h.presenter.calls.contains(.showSnoozed(.gym, day(2026, 3, 4, 11))))
    }

    @Test func ignoredPopupComesBackNextIntervalAtGentle() {
        let h = harness(at: day(2026, 3, 4, 9)) {
            $0.prefs.general.ignoreMinutes = 5
            $0.prefs.gym.strictness = .persistent
        }
        h.advance(minutes: 60)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        h.advance(minutes: 5)
        #expect(h.engine.activities[.gym] == nil)
        let shows = h.presenter.calls.filter { $0 == .showBubble(.gym, .nudge) }.count
        h.advance(minutes: 50)
        #expect(h.engine.activities[.gym] == nil)
        h.advance(minutes: 10)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        #expect(h.presenter.calls.filter { $0 == .showBubble(.gym, .nudge) }.count == shows + 1)
        #expect(!h.presenter.calls.contains(.showBubble(.gym, .persist)))
    }

    @Test func snoozeButtonIsANormalSnooze() {
        let h = atTen { $0.prefs.gym.strictness = .persistent }
        h.engine.snooze(.gym)
        let until = day(2026, 3, 4, 10).addingTimeInterval(TimeInterval(h.engine.data.prefs.general.snoozeMinutes) * Timing.minute)
        #expect(h.engine.state(.gym).snoozedUntil == until)
        h.advance(minutes: Double(h.engine.data.prefs.general.snoozeMinutes))
        #expect(h.engine.phase(.gym) == .bubble(.persist))
    }

    @Test func notNowLeavesOtherHabitsAlone() {
        let h = harness(at: day(2026, 3, 4, 9)) {
            $0.prefs.water.enabled = true
            $0.live.lastWaterDone = day(2026, 3, 4, 8)
        }
        h.advance(minutes: 60)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        let waterDeadline = deadline(h, .water)
        h.engine.notNow(.gym)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(deadline(h, .water) == waterDeadline)
    }

    @Test func remindersContinueAfterFourWorkouts() {
        let h = harness(at: day(2026, 3, 4, 14)) {
            $0.events = [10, 11, 12, 13].map { .done(.gym, 1, at: day(2026, 3, 4, $0, 30)) }
        }
        #expect(h.engine.activities[.gym] == nil)
        h.advance(minutes: 60)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
    }

    @Test func noReminderOnSaturday() {
        let h = harness(at: day(2026, 3, 7, 9))
        h.advance(minutes: 8 * 60)
        #expect(!h.presenter.calls.contains { if case .showBubble(.gym, _) = $0 { true } else { false } })
    }
}
