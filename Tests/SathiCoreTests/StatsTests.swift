import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Stats")
struct StatsTests {
    private let stats = Stats()
    private let today = day(2026, 3, 4, 12)

    @Test func glassesSumsOnlyThatDay() {
        let events: [HistoryEvent] = [
            .done(.water, 1, at: day(2026, 3, 4, 10)),
            .done(.water, 0.5, at: day(2026, 3, 4, 15)),
            .done(.water, 2, at: day(2026, 3, 5, 10)),
            .done(.reading, 15, at: day(2026, 3, 4, 22)),
            .snooze(.water, at: day(2026, 3, 4, 11))
        ]
        #expect(stats.total(.water, on: today, in: events) == 1.5)
    }

    @Test func readMinutesSumsOnlyThatDay() {
        let events: [HistoryEvent] = [
            .done(.reading, 15, at: day(2026, 3, 4, 22)),
            .done(.reading, 15, at: day(2026, 3, 3, 22)),
            .done(.water, 2, at: day(2026, 3, 4, 10))
        ]
        #expect(stats.total(.reading, on: today, in: events) == 15)
    }
}
