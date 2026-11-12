import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine gym minutes")
struct EngineGymMinutesTests {
    private func ideasHarness(_ events: [HistoryEvent], ideas: [String] = ["A", "B", "C"]) -> EngineHarness {
        let h = gymHarness(at: day(2026, 3, 4, 9)) {
            $0.prefs.gym.ideas = ideas
            $0.live.gymMinutesSince = day(2026, 3, 4, 7)
            $0.events = events
        }
        h.advance(minutes: 60)
        return h
    }

    @Test func aFreshStateStartsCountingRealMinutesNow() {
        let h = gymHarness(at: day(2026, 3, 4, 10))
        #expect(h.engine.data.live.gymMinutesSince == day(2026, 3, 4, 10))
        #expect(h.store.live.gymMinutesSince == day(2026, 3, 4, 10))
    }

    @Test func aSavedCutoverIsKept() {
        let h = gymHarness(at: day(2026, 3, 4, 10)) { $0.live.gymMinutesSince = day(2026, 2, 1) }
        #expect(h.engine.data.live.gymMinutesSince == day(2026, 2, 1))
    }

    @Test func anOldGymDoneCountsFiveMinutesTowardTheGoalText() {
        let h = gymHarness(at: day(2026, 3, 4, 10)) { $0.events = [.done(.gym, 1, at: day(2026, 3, 4, 9, 30))] }
        #expect(h.engine.goalText(.gym) == GoalText(done: "5", rest: "of 20 min"))
    }

    @Test func aNewGymDoneCountsItsOwnMinutes() {
        let h = gymHarness(at: day(2026, 3, 4, 10)) {
            $0.live.gymMinutesSince = day(2026, 3, 4, 9)
            $0.events = [.done(.gym, 2, at: day(2026, 3, 4, 9, 30))]
        }
        #expect(h.engine.goalText(.gym) == GoalText(done: "2", rest: "of 20 min"))
    }

    @Test func goalTextIsCappedAtTheGoal() {
        let h = gymHarness(at: day(2026, 3, 4, 14)) {
            $0.live.gymMinutesSince = day(2026, 3, 4, 7)
            $0.events = [.done(.gym, 15, at: day(2026, 3, 4, 10)), .done(.gym, 15, at: day(2026, 3, 4, 12))]
        }
        #expect(h.engine.goalText(.gym) == GoalText(done: "20", rest: "of 20 min"))
    }

    @Test func fourOldWorkoutsMeetTheNewGoal() {
        let h = gymHarness(at: day(2026, 3, 4, 14)) {
            $0.events = [10, 11, 12, 13].map { .done(.gym, 1, at: day(2026, 3, 4, $0)) }
        }
        #expect(h.engine.state(.gym).nextDue == day(2026, 3, 5, 10))
    }

    @Test func aDoneSessionAddsItsMinutesToTheGoalText() {
        let h = gymAtTen()
        h.engine.startSession(.gym)
        h.advance(minutes: 3)
        h.engine.finishSession(.gym)
        #expect(h.engine.goalText(.gym) == GoalText(done: "3", rest: "of 20 min"))
    }

    @Test func theDaySummaryGymRowSaysMinutes() {
        #expect(Copywriter.daySummaryValue(.gym, done: 5, goal: 20) == GoalText(done: "5", rest: "of 20 min"))
    }

    @Test func theReportDayCellCountsNewMinutes() throws {
        let h = gymHarness(at: day(2026, 3, 4, 10)) {
            $0.live.gymMinutesSince = day(2026, 3, 4, 7)
            $0.events = [.done(.gym, 7, at: day(2026, 3, 4, 9))]
        }
        let today = StatsRange.containing(h.clock.now, kind: .day, calendar: h.engine.calendar)
        let row = try #require(h.engine.reportsOverview(today).rows.first { $0.habit == .gym })
        #expect(row.cells.first?.text == "7m")
        #expect(row.cells.first?.state == .some)
    }

    @Test func noDoneTodayShowsTheFirstIdea() {
        let h = ideasHarness([])
        #expect(h.engine.gymWorkoutIndex == 0)
        #expect(h.engine.gymIdeaText == "A")
    }

    @Test func rotationCountsSessionsNotMinutes() {
        let h = ideasHarness([.done(.gym, 2, at: day(2026, 3, 4, 8))])
        #expect(h.engine.gymWorkoutIndex == 1)
        #expect(h.engine.gymIdeaText == "B")
    }

    @Test func yesterdaysSessionsDoNotMoveTheIdea() {
        let h = ideasHarness([.done(.gym, 5, at: day(2026, 3, 3, 12))])
        #expect(h.engine.gymIdeaText == "A")
    }

    @Test func nextIdeaAddsOne() {
        let h = ideasHarness([.done(.gym, 2, at: day(2026, 3, 4, 8))])
        h.engine.nextGymIdea()
        #expect(h.engine.gymIdeaText == "C")
    }

    @Test func threeIdeasWrapAround() {
        let h = ideasHarness([.done(.gym, 2, at: day(2026, 3, 4, 8)), .done(.gym, 2, at: day(2026, 3, 4, 8, 10))])
        #expect(h.engine.gymIdeaText == "C")
        h.engine.nextGymIdea()
        #expect(h.engine.gymWorkoutIndex == 0)
        #expect(h.engine.gymIdeaText == "A")
    }

    @Test func aRunningSessionKeepsItsIdea() {
        let h = ideasHarness([])
        h.engine.nextGymIdea()
        h.engine.startSession(.gym)
        h.engine.data.events.append(.done(.gym, 2, at: day(2026, 3, 4, 10)))
        #expect(h.engine.gymIdeaText == "B")
    }

    @Test func sessionLengthIsTheSessionMinutes() {
        let h = gymAtTen { $0.prefs.gym.sessionMinutes = 10 }
        h.engine.startSession(.gym)
        let s = h.engine.session(.gym)
        #expect(s.map { $0.end.timeIntervalSince($0.start) } == 10 * Timing.minute)
    }
}
