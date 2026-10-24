import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Meditation review fixes")
struct MeditationReviewFixTests {
    private func encodedSlots(_ slots: Set<MeditationSlot>) throws -> [String] {
        var prefs = MeditationPrefs()
        prefs.slots = slots
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(prefs)) as? [String: Any]
        return object?["slots"] as? [String] ?? []
    }

    @Test func lastDoneIsTheLatestDoneEventInAnyOrder() {
        var data = Persisted()
        data.events = [
            .done(.meditation, 5, at: day(2026, 3, 4, 8, 5)),
            .done(.meditation, 5, at: day(2026, 3, 3, 21, 35)),
            .done(.meditation, 5, at: day(2026, 3, 2, 8, 5))
        ]
        #expect(data.lastDone(.meditation) == day(2026, 3, 4, 8, 5))
    }

    @Test(arguments: [
        (Set<MeditationSlot>([.evening, .morning, .afternoon]), ["morning", "afternoon", "evening"]),
        (Set<MeditationSlot>([.evening, .afternoon]), ["afternoon", "evening"]),
        (Set<MeditationSlot>([.evening, .morning]), ["morning", "evening"]),
        (Set<MeditationSlot>([.afternoon, .morning]), ["morning", "afternoon"])
    ])
    func slotsEncodeInSlotOrder(_ slots: Set<MeditationSlot>, _ expected: [String]) throws {
        #expect(try encodedSlots(slots) == expected)
    }

    @Test func slotsEncodeTheSameEveryTime() throws {
        let all: Set<MeditationSlot> = [.morning, .afternoon, .evening]
        let outputs = try (0 ..< 20).map { _ in try encodedSlots(Set(Array(all).shuffled())) }
        #expect(Set(outputs.map { $0.joined(separator: ",") }) == ["morning,afternoon,evening"])
    }

    @Test func slotsDecodeFromAnyOrder() throws {
        let prefs = try JSONDecoder().decode(MeditationPrefs.self, from: Data(#"{"slots":["evening","morning"]}"#.utf8))
        #expect(prefs.slots == [.morning, .evening])
    }

    @Test(arguments: [(MeditationSlot.morning, 8 * 60), (.afternoon, 14 * 60), (.evening, 21 * 60 + 30)])
    func slotMinutes(_ slot: MeditationSlot, _ minutes: Int) {
        #expect(slot.minutes == minutes)
    }
}
