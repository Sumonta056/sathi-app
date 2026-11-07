import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("GymRules data")
struct GymRulesDataTests {
    private let rules = GymRules(prefs: Prefs())

    @Test func lastDoneIsTheLastDoneGymEvent() {
        var data = Persisted()
        #expect(data.lastDone(.gym) == nil)
        data.events = [
            .done(.gym, 5, at: day(2026, 3, 4, 10)),
            .done(.gym, 5, at: day(2026, 3, 4, 11)),
            .snooze(.gym, at: day(2026, 3, 4, 14)),
            .done(.meditation, 5, at: day(2026, 3, 4, 15))
        ]
        #expect(data.lastDone(.gym) == day(2026, 3, 4, 11))
    }

    @Test func totalSumsThatDaysMinutes() {
        var data = Persisted()
        data.events = [
            .done(.gym, 5, at: day(2026, 3, 3, 16)),
            .done(.gym, 5, at: day(2026, 3, 4, 10)),
            .done(.gym, 2, at: day(2026, 3, 4, 11)),
            .skip(.gym, at: day(2026, 3, 4, 12))
        ]
        #expect(rules.total(on: day(2026, 3, 4, 12), data: data) == 7)
    }
}
