import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Next slot")
struct NextSlotTests {
    private func meditation(_ slots: Set<MeditationSlot>) -> MeditationRules {
        var prefs = Prefs()
        prefs.meditation.slots = slots
        return MeditationRules(prefs: prefs)
    }

    @Test(arguments: [
        (day(2026, 3, 4, 7), day(2026, 3, 4, 8)),
        (day(2026, 3, 4, 8), day(2026, 3, 4, 21, 30)),
        (day(2026, 3, 4, 15), day(2026, 3, 4, 21, 30)),
        (day(2026, 3, 4, 21, 30), day(2026, 3, 5, 8)),
        (day(2026, 3, 4, 23), day(2026, 3, 5, 8))
    ])
    func meditationNextSelectedSlotStrictlyAfter(_ date: Date, _ expected: Date) {
        #expect(meditation([.morning, .evening]).nextSlot(after: date) == expected)
    }

    @Test func meditationWithAfternoonSlot() {
        #expect(meditation([.afternoon]).nextSlot(after: day(2026, 3, 4, 16)) == day(2026, 3, 5, 14))
        #expect(meditation([.morning, .afternoon, .evening]).nextSlot(after: day(2026, 3, 4, 9)) == day(2026, 3, 4, 14))
    }

    @Test func meditationWithNoSlotsHasNoNextSlot() {
        #expect(meditation([]).nextSlot(after: day(2026, 3, 4, 15)) == nil)
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
        case .meditation: #expect(slot == day(2026, 3, 4, 21, 30))
        }
    }
}
