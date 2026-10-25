import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Meditation prefs")
struct MeditationPrefsTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test func habitNamesAndRawValue() {
        #expect(HabitID.meditation.rawValue == "meditation")
        #expect(HabitID.meditation.name == "Meditation")
        #expect(HabitID.meditation.buddy == "Shanti")
        #expect(HabitID.allCases == [.water, .reading, .meditation])
    }

    @Test func defaults() {
        let m = MeditationPrefs()
        #expect(!m.enabled)
        #expect(m.dailyGoalMinutes == 10)
        #expect(m.sessionMinutes == 2)
        #expect(m.intervalMinutes == 60)
        #expect(m.startMinutes == 9 * 60)
        #expect(m.endMinutes == 21 * 60)
        #expect(m.style == .box)
        #expect(m.chime)
        #expect(m.strictness == .friendly)
        #expect(Prefs().meditation == m)
        #expect(!Prefs().isEnabled(.meditation))
    }

    @Test func rawValuesAreStable() {
        #expect(BreathingStyle.allCases.map(\.rawValue) == ["box", "relax", "even"])
    }

    @Test func lengthsGoalsAndIntervals() {
        #expect(Limits.meditationLengths == [1, 2, 5])
        #expect(Limits.meditationGoals == [5, 10, 20])
        #expect(Limits.meditationIntervalChips == [30, 60, 90, 120])
    }

    @Test func emptyJSONDecodesToDefaults() throws {
        #expect(try decode(MeditationPrefs.self, "{}") == MeditationPrefs())
    }

    @Test func prefsWithoutMeditationDecodeToMeditationDefaults() throws {
        let p = try decode(Prefs.self, #"{"water":{"intervalMinutes":60},"reading":{"enabled":false}}"#)
        #expect(p.meditation == MeditationPrefs())
        #expect(p.water.intervalMinutes == 60)
        #expect(!p.reading.enabled)
    }

    @Test func oneKnownKeyKeepsTheOtherDefaults() throws {
        var expected = MeditationPrefs()
        expected.sessionMinutes = 10
        #expect(try decode(MeditationPrefs.self, #"{"sessionMinutes":10}"#) == expected)
        var prefs = Prefs()
        prefs.meditation.enabled = true
        #expect(try decode(Prefs.self, #"{"meditation":{"enabled":true}}"#) == prefs)
    }

    @Test func roundTrip() throws {
        var p = Prefs()
        p.meditation.enabled = true
        p.meditation.dailyGoalMinutes = 20
        p.meditation.intervalMinutes = 90
        p.meditation.startMinutes = 7 * 60 + 30
        p.meditation.endMinutes = 22 * 60
        p.meditation.sessionMinutes = 5
        p.meditation.style = .relax
        p.meditation.chime = false
        p.meditation.strictness = .persistent
        #expect(try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p)) == p)
    }

    @Test func scheduleKeyTracksMeditationScheduleFields() {
        let base = Prefs()
        let changes: [(inout MeditationPrefs) -> Void] = [
            { $0.enabled = true },
            { $0.dailyGoalMinutes = 20 },
            { $0.sessionMinutes = 5 },
            { $0.intervalMinutes = 90 },
            { $0.startMinutes = 10 * 60 },
            { $0.endMinutes = 20 * 60 }
        ]
        for change in changes {
            var p = base
            change(&p.meditation)
            #expect(p.scheduleKey != base.scheduleKey)
        }
    }

    @Test func scheduleKeyIgnoresStyleAndChime() {
        var p = Prefs()
        let key = p.scheduleKey
        p.meditation.style = .even
        p.meditation.chime = false
        #expect(p.scheduleKey == key)
    }

    @Test func waterAndMeditationMayBeStrictButReadingMayNot() {
        var p = Prefs()
        p.water.strictness = .strict
        p.reading.strictness = .strict
        p.meditation.strictness = .strict
        #expect(p.strictness(.water) == .strict)
        #expect(p.strictness(.reading) == .persistent)
        #expect(p.strictness(.meditation) == .strict)
    }

    @Test(arguments: [Strictness.friendly, .persistent])
    func nonStrictValuesAreKept(_ s: Strictness) {
        var p = Prefs()
        p.reading.strictness = s
        p.meditation.strictness = s
        #expect(p.strictness(.reading) == s)
        #expect(p.strictness(.meditation) == s)
    }
}
