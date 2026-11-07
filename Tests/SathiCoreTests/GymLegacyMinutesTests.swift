import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Gym legacy minutes")
struct GymLegacyMinutesTests {
    private let since = day(2026, 3, 4, 12)

    @Test func noCutoverLeavesEveryEventAsItIs() {
        let events: [HistoryEvent] = [.done(.gym, 1, at: day(2026, 3, 4, 10)), .done(.gym, 2, at: day(2026, 3, 4, 13))]
        #expect(GymLegacyMinutes.apply(events, since: nil) == events)
    }

    @Test func aGymDoneBeforeTheCutoverCountsFiveMinutes() {
        let out = GymLegacyMinutes.apply([.done(.gym, 1, at: day(2026, 3, 4, 10))], since: since)
        #expect(out == [.done(.gym, Double(Limits.gymLegacyDoneMinutes), at: day(2026, 3, 4, 10))])
        #expect(out.first?.amount == 5)
    }

    @Test(arguments: [day(2026, 3, 4, 12), day(2026, 3, 4, 13)])
    func aGymDoneAtOrAfterTheCutoverKeepsItsMinutes(_ at: Date) {
        let events: [HistoryEvent] = [.done(.gym, 2, at: at)]
        #expect(GymLegacyMinutes.apply(events, since: since) == events)
    }

    @Test func otherHabitsAndOtherKindsAreNeverChanged() {
        let at = day(2026, 3, 4, 10)
        let events: [HistoryEvent] = [
            .done(.water, 1, at: at),
            .done(.reading, 15, at: at),
            .done(.meditation, 3, at: at),
            .snooze(.gym, at: at),
            .skip(.gym, at: at)
        ]
        #expect(GymLegacyMinutes.apply(events, since: since) == events)
    }

    @Test func orderAndCountStayTheSame() {
        let events: [HistoryEvent] = [
            .done(.gym, 1, at: day(2026, 3, 3, 10)),
            .done(.water, 2, at: day(2026, 3, 4, 9)),
            .done(.gym, 1, at: day(2026, 3, 4, 11)),
            .done(.gym, 3, at: day(2026, 3, 4, 14))
        ]
        let out = GymLegacyMinutes.apply(events, since: since)
        #expect(out.map(\.date) == events.map(\.date))
        #expect(out.map(\.habit) == events.map(\.habit))
        #expect(out.map(\.amount) == [5, 2, 5, 3])
    }
}
