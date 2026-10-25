import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Next slot")
struct NextSlotTests {
    @Test(arguments: [day(2026, 3, 4, 7), day(2026, 3, 4, 15), day(2026, 3, 4, 23)])
    func meditationHasNoSlot(_ date: Date) {
        #expect(MeditationRules(prefs: Prefs()).nextSlot(after: date) == nil)
    }

    @Test(arguments: [
        (day(2026, 3, 4, 10), day(2026, 3, 4, 22)),
        (day(2026, 3, 4, 22), day(2026, 3, 5, 22)),
        (day(2026, 3, 4, 23), day(2026, 3, 5, 22))
    ])
    func readingNextTimeStrictlyAfter(_ date: Date, _ expected: Date) {
        #expect(ReadingRules(prefs: Prefs()).nextSlot(after: date) == expected)
    }

    @Test func waterHasNoSlot() {
        #expect(WaterRules(prefs: Prefs()).nextSlot(after: day(2026, 3, 4, 10)) == nil)
    }

    @Test(arguments: HabitID.allCases)
    func everyHabitAnswersThroughTheProtocol(_ id: HabitID) {
        let slot = id.rules(Prefs()).nextSlot(after: day(2026, 3, 4, 10))
        switch id {
        case .water: #expect(slot == nil)
        case .reading: #expect(slot == day(2026, 3, 4, 22))
        case .meditation: #expect(slot == nil)
        }
    }
}
