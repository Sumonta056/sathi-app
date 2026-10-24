import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Model")
struct ModelTests {
    @Test func scheduleKeyIgnoresNonScheduleFields() {
        var p = Prefs()
        let key = p.scheduleKey
        p.name = "Other"
        p.soundOn.toggle()
        p.snoozeMinutes = 9
        #expect(p.scheduleKey == key)
    }

    @Test func scheduleKeyTracksScheduleFields() {
        var p = Prefs()
        let key = p.scheduleKey
        p.waterIntervalMinutes = 60
        #expect(p.scheduleKey != key)
    }

    @Test func persistedRoundTrip() throws {
        var state = Persisted()
        state.drinks = [DrinkEntry(date: day(2026, 1, 2, 10), glasses: 1.5)]
        state.reads = [ReadEntry(date: day(2026, 1, 2, 22), minutes: 15)]
        state.bottleLevel = 0.4
        let decoded = try JSONDecoder().decode(Persisted.self, from: JSONEncoder().encode(state))
        #expect(decoded == state)
    }

    @Test func defaultPrefs() {
        let p = Prefs()
        #expect(p.waterIntervalMinutes == 120)
        #expect(p.waterStartMinutes == 570)
        #expect(p.waterEndMinutes == 1110)
        #expect(p.readingTimeMinutes == 1320)
        #expect(p.waterStrictness == .strict)
        #expect(p.readingStrictness == .persistent)
    }

    @Test func perHabitAccessors() {
        var p = Prefs()
        p.readingEnabled = false
        #expect(p.isEnabled(.water))
        #expect(!p.isEnabled(.reading))
        #expect(p.strictness(.water) == .strict)
        #expect(p.strictness(.reading) == .persistent)
    }

    @Test(arguments: HabitID.allCases)
    func rulesMatchTheirHabit(_ id: HabitID) {
        #expect(id.rules(Prefs()).id == id)
    }
}
