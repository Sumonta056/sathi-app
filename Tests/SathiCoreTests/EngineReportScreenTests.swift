import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine report screen")
struct EngineReportScreenTests {
    private func met(_ days: [Int], month: Int) -> [HistoryEvent] {
        days.map { .done(.water, 8, at: day(2026, month, $0, 12)) }
    }

    private func harness() -> EngineHarness {
        EngineHarness {
            $0.events = met([10, 11, 12, 13, 14], month: 2) + met([1, 2, 3], month: 3)
            $0.prefs.reading.enabled = false
        }
    }

    @Test func anOffSelectionUsesTheFallbackHabitForStreaks() {
        let h = harness()
        let screen = h.engine.reportScreen(.week, selected: .reading)
        #expect(screen.selected == .water)
        #expect(screen.calendar.streakText == "3 days")
        #expect(screen.facts.first { $0.label == "Longest streak" }?.value == "5 days")
        #expect(screen.chart.title == "Water · this week")
    }

    @Test func theScreenIsBuiltFromTheEngineReportsAndPrefs() {
        let h = harness()
        let expected = ReportScreenBuilder(calendar: .current).build(ReportScreenInput(
            range: .month,
            selected: .reading,
            report: h.engine.report(.month),
            month: h.engine.report(.month),
            enabled: [.water],
            streak: 3,
            longest: 5,
            now: h.clock.now
        ))
        #expect(h.engine.reportScreen(.month, selected: .reading) == expected)
    }

    @Test func turningAHabitOnMakesItSelectable() {
        let h = harness()
        h.engine.data.prefs.reading.enabled = true
        let screen = h.engine.reportScreen(.week, selected: .reading)
        #expect(screen.selected == .reading)
        #expect(screen.calendar.streakText == "0 days")
        #expect(screen.tiles.first { $0.habit == .reading }?.isOff == false)
    }

    @Test func openReportsShowsTheReportsWindow() {
        let h = harness()
        h.engine.openReports()
        #expect(h.presenter.calls.last == .showReports)
    }

    private func gymHarness(workouts: Int) -> EngineHarness {
        EngineHarness {
            $0.prefs.gym.enabled = true
            $0.events = (0 ..< workouts).map { .done(.gym, 1, at: day(2026, 3, 4, 9, $0 * 10)) }
        }
    }

    @Test func theGymTileCountsWorkoutsAgainstAGoalOfFour() throws {
        let h = gymHarness(workouts: 2)
        let tile = try #require(h.engine.reportScreen(.day, selected: .gym).tiles.first { $0.habit == .gym })
        #expect(tile.value == "2")
        #expect(tile.unit == "workouts today")
        #expect(tile.percent == 50)
        #expect(!tile.isOff)
    }

    @Test func fourWorkoutsMeetTheGymGoalOnTheCalendar() throws {
        let h = gymHarness(workouts: 4)
        let screen = h.engine.reportScreen(.month, selected: .gym)
        #expect(screen.selected == .gym)
        let today = try #require(screen.calendar.cells.first { $0.isToday })
        #expect(today.level == 3)
    }

    @Test func threeWorkoutsLeaveTheGymGoalUnmet() throws {
        let h = gymHarness(workouts: 3)
        let today = try #require(h.engine.reportScreen(.month, selected: .gym).calendar.cells.first { $0.isToday })
        #expect(today.level == 2)
    }
}
