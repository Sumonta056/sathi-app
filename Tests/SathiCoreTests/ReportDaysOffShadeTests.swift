import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Report days off best day and shade")
struct ReportDaysOffShadeTests {
    private let zone = FixedZone.berlin
    private let workdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]

    @Test func anUnmetOffDayCanStillBeTheBestDay() throws {
        var prefs = Prefs()
        prefs.gym.weekdays = workdays
        let amounts: [Int: Double] = [2: 2, 3: 2, 4: 2, 5: 2, 6: 2, 7: 3]
        let events = amounts.map { HistoryEvent.done(.gym, $0.value, at: zone.date(2026, 3, $0.key, 12)) }
        let report = ReportBuilder(calendar: zone.calendar).build(.week, now: zone.date(2026, 3, 8, 23), events: events, prefs: prefs)
        let gym = try #require(report.habits.first { $0.habit == .gym })
        #expect(gym.bestDay == zone.date(2026, 3, 7))
    }

    @MainActor
    @Test func anOffDayWithSomeProgressIsOffAndUnshaded() throws {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) {
            $0.prefs.water.weekdays = workdays
            $0.events = [.done(.water, 2, at: day(2026, 3, 7, 12))]
        }
        let month = h.engine.reportScreen(.month, selected: .water).calendar
        let saturday = try #require(month.cells.first { $0.day == 7 })
        #expect(saturday.isOff)
        #expect(saturday.level == 0)
    }
}
