import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine dashboard score")
struct EngineDashboardScoreTests {
    private static let now = day(2026, 11, 11, 20)

    private static func harness(_ events: [HistoryEvent], edit: @escaping (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness(at: now) {
            $0.prefs.water.dailyGoalGlasses = 8
            $0.prefs.reading.sessionMinutes = 15
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.dailyGoalMinutes = 10
            $0.prefs.gym.enabled = true
            $0.prefs.gym.sessionsPerDay = 2
            $0.prefs.gym.sessionMinutes = 5
            $0.live.gymMinutesSince = day(2026, 1, 1)
            $0.events = events
            edit(&$0)
        }
    }

    private static let yesterdayTwoGoals: [HistoryEvent] = [
        .done(.water, 8, at: day(2026, 11, 10, 9)),
        .done(.meditation, 10, at: day(2026, 11, 10, 11))
    ]

    @Test func metAndPossibleCountTodaysGoalsOfEveryBuddyThatIsOn() throws {
        let h = Self.harness(Self.yesterdayTwoGoals + [
            .done(.water, 8, at: day(2026, 11, 11, 9)),
            .done(.reading, 15, at: day(2026, 11, 11, 10)),
            .done(.meditation, 10, at: day(2026, 11, 11, 11)),
            .done(.gym, 5, at: day(2026, 11, 11, 12))
        ])
        let score = try #require(h.engine.dashboardScore)
        #expect(score.met == 3)
        #expect(score.possible == 4)
    }

    @Test func oneMoreGoalThanYesterdayReadsPlusOne() throws {
        let h = Self.harness(Self.yesterdayTwoGoals + [
            .done(.water, 8, at: day(2026, 11, 11, 9)),
            .done(.reading, 15, at: day(2026, 11, 11, 10)),
            .done(.meditation, 10, at: day(2026, 11, 11, 11))
        ])
        let score = try #require(h.engine.dashboardScore)
        #expect(score.changeText == "+1 vs yesterday")
        #expect(score.isUp)
    }

    @Test func theSameGoalsAsYesterdayReadsSame() throws {
        let h = Self.harness(Self.yesterdayTwoGoals + [
            .done(.water, 8, at: day(2026, 11, 11, 9)),
            .done(.reading, 15, at: day(2026, 11, 11, 10))
        ])
        let score = try #require(h.engine.dashboardScore)
        #expect(score.met == 2)
        #expect(score.changeText == "same as yesterday")
        #expect(!score.isUp)
    }

    @Test func fewerGoalsThanYesterdayReadsMinus() throws {
        let h = Self.harness(Self.yesterdayTwoGoals + [.done(.water, 8, at: day(2026, 11, 11, 9))])
        let score = try #require(h.engine.dashboardScore)
        #expect(score.met == 1)
        #expect(score.changeText == "\u{2212}1 vs yesterday")
        #expect(!score.isUp)
    }

    @Test func yesterdayIsCutAtTheSameClockTimeAsNow() throws {
        let h = Self.harness(Self.yesterdayTwoGoals + [
            .done(.reading, 15, at: day(2026, 11, 10, 21)),
            .done(.water, 8, at: day(2026, 11, 11, 9)),
            .done(.reading, 15, at: day(2026, 11, 11, 10)),
            .done(.meditation, 10, at: day(2026, 11, 11, 11))
        ])
        let score = try #require(h.engine.dashboardScore)
        #expect(score.changeText == "+1 vs yesterday")
    }

    @Test func aBuddyDayOffTodayWithoutItsGoalIsNotPossible() throws {
        let h = Self.harness(Self.yesterdayTwoGoals) {
            $0.prefs.gym.daysOff = [DayKey(day(2026, 11, 11), calendar: .current)]
        }
        let score = try #require(h.engine.dashboardScore)
        #expect(score.possible == 3)
    }

    @Test func noBuddyOnGivesNoScore() {
        let h = Self.harness(Self.yesterdayTwoGoals) {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            $0.prefs.meditation.enabled = false
            $0.prefs.gym.enabled = false
        }
        #expect(h.engine.dashboardScore == nil)
    }

    @Test func noDataInBothDaysHidesTheChange() throws {
        let h = Self.harness([.done(.water, 8, at: day(2026, 11, 3, 9))])
        let score = try #require(h.engine.dashboardScore)
        #expect(score.met == 0)
        #expect(score.possible == 4)
        #expect(score.changeText.isEmpty)
    }
}
