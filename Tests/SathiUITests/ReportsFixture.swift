import Foundation
import SathiCore
import SathiTestSupport

enum ReportsFixture {
    static let now = day(2026, 11, 11, 20)

    static func week() -> StatsRange {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return StatsRange.containing(now, kind: .week, calendar: calendar)
    }

    @MainActor
    static func harness() -> EngineHarness {
        EngineHarness(at: now) {
            $0.prefs.water.dailyGoalGlasses = 8
            $0.prefs.reading.sessionMinutes = 15
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.dailyGoalMinutes = 10
            $0.prefs.gym.enabled = true
            $0.prefs.gym.sessionsPerDay = 2
            $0.prefs.gym.sessionMinutes = 5
            $0.live.gymMinutesSince = day(2026, 1, 1)
            $0.events = [
                .done(.water, 8, at: day(2026, 11, 9, 9)),
                .done(.water, 8, at: day(2026, 11, 10, 9)),
                .done(.water, 3, at: day(2026, 11, 11, 9)),
                .done(.reading, 15, at: day(2026, 11, 9, 10)),
                .done(.reading, 5, at: day(2026, 11, 10, 10)),
                .done(.meditation, 10, at: day(2026, 11, 9, 11)),
                .done(.meditation, 10, at: day(2026, 11, 10, 11)),
                .done(.meditation, 10, at: day(2026, 11, 11, 11)),
                .done(.gym, 10, at: day(2026, 11, 9, 12)),
                .done(.water, 8, at: day(2026, 11, 3, 9))
            ]
        }
    }
}
