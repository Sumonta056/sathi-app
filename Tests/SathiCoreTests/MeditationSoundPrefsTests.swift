import Foundation
import SathiCore
import Testing

@Suite("Meditation sound prefs")
struct MeditationSoundPrefsTests {
    private func decode(_ json: String) throws -> MeditationPrefs {
        try JSONDecoder().decode(MeditationPrefs.self, from: Data(json.utf8))
    }

    @Test func defaults() {
        let m = MeditationPrefs()
        #expect(m.voiceOn)
        #expect(m.voiceVolume == 0.8)
        #expect(m.musicOn)
        #expect(m.musicVolume == 0.5)
        #expect(!m.minuteTick)
    }

    @Test func oldJSONWithoutTheKeysGetsDefaultsAndKeepsTheGoal() throws {
        let m = try decode(#"{"enabled":true,"dailyGoalMinutes":20,"style":"box"}"#)
        #expect(m.voiceOn)
        #expect(m.voiceVolume == 0.8)
        #expect(m.musicOn)
        #expect(m.musicVolume == 0.5)
        #expect(!m.minuteTick)
        #expect(m.dailyGoalMinutes == 20)
    }

    @Test func savedValuesAreRead() throws {
        let m = try decode(#"{"voiceOn":false,"voiceVolume":0.3,"musicOn":false,"musicVolume":0.9,"minuteTick":true}"#)
        #expect(!m.voiceOn)
        #expect(m.voiceVolume == 0.3)
        #expect(!m.musicOn)
        #expect(m.musicVolume == 0.9)
        #expect(m.minuteTick)
    }

    @Test func volumesAreClampedToTheSessionRange() throws {
        let high = try decode(#"{"voiceVolume":1.7,"musicVolume":1.7}"#)
        #expect(high.voiceVolume == Limits.sessionVolume.upperBound)
        #expect(high.musicVolume == 1)
        let low = try decode(#"{"voiceVolume":-0.2,"musicVolume":-0.2}"#)
        #expect(low.voiceVolume == Limits.sessionVolume.lowerBound)
        #expect(low.musicVolume == 0)
    }

    @Test func roundTrip() throws {
        var m = MeditationPrefs()
        m.voiceOn = false
        m.voiceVolume = 0.4
        m.musicOn = false
        m.musicVolume = 0.2
        m.minuteTick = true
        let back = try JSONDecoder().decode(MeditationPrefs.self, from: JSONEncoder().encode(m))
        #expect(back == m)
    }
}
