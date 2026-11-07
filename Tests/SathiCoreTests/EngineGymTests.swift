import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
func doneEvents(_ h: EngineHarness) -> [HistoryEvent] {
    h.history.appended.filter { $0.kind == .done }
}

@MainActor
func deadline(_ h: EngineHarness, _ id: HabitID) -> Date? {
    guard case let .bubble(_, _, d) = h.engine.activities[id] else { return nil }
    return d
}

@MainActor
func gymHarness(at start: Date, configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
    EngineHarness(at: start) {
        $0.prefs.gym.enabled = true
        $0.prefs.water.enabled = false
        $0.prefs.reading.enabled = false
        configure(&$0)
    }
}

@MainActor
func gymAtTen(configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
    let h = gymHarness(at: day(2026, 3, 4, 9), configure: configure)
    h.advance(minutes: 60)
    return h
}

@MainActor
@Suite("Engine gym")
struct EngineGymTests {
    @Test func firstReminderShowsAtTenInTheCorner() {
        let h = gymHarness(at: day(2026, 3, 4, 9))
        h.advance(minutes: 60)
        #expect(h.presenter.calls.contains(.showBubble(.gym, .nudge)))
        #expect(h.engine.usesCorner(.gym))
    }

    @Test func firstWorkoutOfTheDayIsWorkoutOne() {
        let h = gymAtTen()
        #expect(h.engine.gymIdeaText == "Neck and shoulder stretch")
    }

    @Test func nextIdeaShowsTheNextWorkoutAndWrapsAfterFour() {
        let h = gymAtTen()
        let before = h.history.appended
        h.engine.nextGymIdea()
        #expect(h.engine.gymIdeaText == "Short walk")
        for _ in 0 ..< 4 {
            h.engine.nextGymIdea()
        }
        #expect(h.engine.gymIdeaText == "Short walk")
        #expect(h.history.appended == before)
    }

    @Test func nextIdeaKeepsTheIgnoreDeadline() {
        let h = gymAtTen()
        let before = deadline(h, .gym)
        #expect(before != nil)
        h.engine.nextGymIdea()
        #expect(deadline(h, .gym) == before)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
    }

    @Test func startRunsTheShownWorkout() {
        let h = gymAtTen()
        h.engine.nextGymIdea()
        h.engine.nextGymIdea()
        h.engine.startSession(.gym)
        let s = h.engine.session(.gym)
        #expect(s?.workout == 2)
        #expect(s.map { $0.end.timeIntervalSince($0.start) } == 5 * Timing.minute)
        #expect(h.engine.gymIdeaText == "10 squats")
        h.engine.data.events.append(.done(.gym, 2, at: day(2026, 3, 4, 10)))
        #expect(h.engine.gymWorkoutIndex == 3)
        #expect(h.engine.gymIdeaText == "10 squats")
    }

    @Test func doneEarlyLogsTheRealMinutes() {
        let h = gymAtTen()
        h.engine.startSession(.gym)
        h.advance(minutes: 2)
        h.engine.finishSession(.gym)
        #expect(h.history.appended.last == .done(.gym, 2, at: day(2026, 3, 4, 10, 2)))
        #expect(h.engine.celebration.amount == 2)
        let d = day(2026, 3, 4, 10, 2)
        #expect(h.engine.state(.gym).nextDue == d.addingTimeInterval(day(2026, 3, 4, 17).timeIntervalSince(d) / 4.5))
    }

    @Test func doneAfterTwentySecondsLogsOneMinute() {
        let h = gymAtTen()
        h.engine.startSession(.gym)
        h.clock.now = day(2026, 3, 4, 10).addingTimeInterval(20)
        h.engine.finishSession(.gym)
        #expect(h.history.appended.last == .done(.gym, 1, at: day(2026, 3, 4, 10).addingTimeInterval(20)))
    }

    @Test func timerEndLogsTheFullSessionAndReSpreadsTheRest() {
        let h = gymAtTen()
        h.engine.startSession(.gym)
        h.advance(minutes: 5)
        #expect(h.history.appended.last == .done(.gym, 5, at: day(2026, 3, 4, 10, 5)))
        #expect(h.engine.celebration.amount == 5)
        let d = day(2026, 3, 4, 10, 5)
        #expect(h.engine.state(.gym).nextDue == d.addingTimeInterval(day(2026, 3, 4, 17).timeIntervalSince(d) / 3.5))
    }

    @Test func aLateTimerEndLogsOnlyTheSessionLength() {
        let h = gymAtTen()
        h.engine.startSession(.gym)
        h.clock.now = day(2026, 3, 4, 10, 9)
        h.engine.finishSession(.gym)
        #expect(h.history.appended.last == .done(.gym, 5, at: day(2026, 3, 4, 10, 9)))
    }

    @Test func stopDoesNotCount() {
        let h = gymAtTen()
        h.engine.startSession(.gym)
        h.engine.stopSession(.gym)
        #expect(doneEvents(h).isEmpty)
    }

    @Test func secondReminderAfterOneDoneShowsWorkoutTwo() {
        let h = gymAtTen()
        h.engine.nextGymIdea()
        h.engine.startSession(.gym)
        h.advance(minutes: 5)
        h.engine.endCelebrate()
        h.advance(minutes: 119)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        #expect(h.engine.gymIdeaText == "Short walk")
        #expect(h.engine.gymIdea == 0)
    }

    @Test func goalMetKeepsShoktiQuietUntilTomorrowsFirstReminder() {
        let h = gymHarness(at: day(2026, 3, 4, 14)) {
            $0.live.gymMinutesSince = day(2026, 3, 4, 8)
            $0.events = [10, 11, 12, 13].map { .done(.gym, 5, at: day(2026, 3, 4, $0, 30)) }
        }
        #expect(h.engine.state(.gym).nextDue == day(2026, 3, 5, 10))
        h.advance(minutes: 60)
        #expect(h.engine.activities[.gym] == nil)
    }

    @Test func noReminderOnSaturday() {
        let h = gymHarness(at: day(2026, 3, 7, 9)) {
            $0.prefs.gym.weekdays = [.monday, .tuesday, .wednesday, .thursday, .friday]
        }
        h.advance(minutes: 8 * 60)
        #expect(!h.presenter.calls.contains { if case .showBubble(.gym, _) = $0 { true } else { false } })
    }
}
